import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/extracted_document.dart';
import '../providers/document_provider.dart';

class ExtractionResultScreen extends StatefulWidget {
  final ExtractedDocument document;

  const ExtractionResultScreen({
    super.key,
    required this.document,
  });

  @override
  State<ExtractionResultScreen> createState() => _ExtractionResultScreenState();
}

class _ExtractionResultScreenState extends State<ExtractionResultScreen> {
  late Map<String, dynamic> _editedData;
  final Map<String, TextEditingController> _controllers = {};
  bool _isEditing = false;
  bool _isSaving = false;
  int? _selectedLineItemIndex;

  @override
  void initState() {
    super.initState();
    _editedData = Map<String, dynamic>.from(widget.document.extractedData);

    // Handle double-nested extracted_data (backward compatibility)
    if (_editedData.containsKey('extracted_data') &&
        _editedData['extracted_data'] is Map) {
      _editedData = _editedData['extracted_data'] as Map<String, dynamic>;
    }

    // Initialize controllers for invoice fields
    if (widget.document.documentType == 'invoice') {
      _initializeInvoiceControllers();
    } else {
      // For non-invoice documents, flatten and initialize controllers
      _editedData = _flattenInvoiceData(_editedData);
      _editedData.forEach((key, value) {
        _controllers[key] = TextEditingController(
          text: _formatValue(value),
        );
      });
    }
  }

  void _initializeInvoiceControllers() {
    final sellerInfo = _editedData['seller_info'] as Map?;
    final customerInfo = _editedData['customer_info'] as Map?;
    final invoiceDetails = _editedData['invoice_details'] as Map?;
    final summary = _editedData['summary'] as Map?;

    _controllers['seller_name'] = TextEditingController(
      text: _safeGetString(sellerInfo, 'name'),
    );
    _controllers['seller_gstin'] = TextEditingController(
      text: _safeGetString(sellerInfo, 'gstin'),
    );

    // Handle contact numbers array
    String sellerContact = 'N/A';
    if (sellerInfo?['contact_numbers'] != null &&
        sellerInfo!['contact_numbers'] is List &&
        (sellerInfo['contact_numbers'] as List).isNotEmpty) {
      sellerContact = (sellerInfo['contact_numbers'] as List).first.toString();
    }
    _controllers['seller_contact'] = TextEditingController(text: sellerContact);

    _controllers['customer_name'] = TextEditingController(
      text: _safeGetString(customerInfo, 'name'),
    );
    _controllers['invoice_date'] = TextEditingController(
      text: _safeGetString(invoiceDetails, 'date'),
    );
    _controllers['bill_number'] = TextEditingController(
      text: _safeGetString(invoiceDetails, 'bill_no'),
    );
    _controllers['grand_total'] = TextEditingController(
      text: _safeGetNumber(summary, 'grand_total').toString(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      Map<String, dynamic> dataToSave;

      if (widget.document.documentType == 'invoice') {
        // Reconstruct the nested structure for invoices
        final sellerInfo = _editedData['seller_info'] as Map? ?? {};
        final customerInfo = _editedData['customer_info'] as Map? ?? {};
        final invoiceDetails = _editedData['invoice_details'] as Map? ?? {};
        final summary = _editedData['summary'] as Map? ?? {};

        // Update with edited values
        sellerInfo['name'] = _controllers['seller_name']?.text ?? 'N/A';
        sellerInfo['gstin'] = _controllers['seller_gstin']?.text ?? 'N/A';
        sellerInfo['contact_numbers'] = [_controllers['seller_contact']?.text ?? 'N/A'];

        customerInfo['name'] = _controllers['customer_name']?.text ?? 'N/A';

        invoiceDetails['date'] = _controllers['invoice_date']?.text ?? 'N/A';
        invoiceDetails['bill_no'] = _controllers['bill_number']?.text ?? 'N/A';

        final grandTotalText = _controllers['grand_total']?.text ?? '0';
        summary['grand_total'] = num.tryParse(grandTotalText) ?? grandTotalText;

        _editedData['seller_info'] = sellerInfo;
        _editedData['customer_info'] = customerInfo;
        _editedData['invoice_details'] = invoiceDetails;
        _editedData['summary'] = summary;

        dataToSave = _editedData;
      } else {
        // For non-invoice documents, use flattened structure
        for (final entry in _controllers.entries) {
          final key = entry.key;
          final controller = entry.value;
          final originalValue = _editedData[key];

          if (originalValue is num) {
            _editedData[key] = num.tryParse(controller.text) ?? controller.text;
          } else if (originalValue is bool) {
            _editedData[key] = controller.text.toLowerCase() == 'true';
          } else {
            _editedData[key] = controller.text;
          }
        }
        dataToSave = _editedData;
      }

      // Create updated document
      final updatedDocument = ExtractedDocument(
        id: widget.document.id,
        documentType: widget.document.documentType,
        fileName: widget.document.fileName,
        extractedData: dataToSave,
        createdAt: widget.document.createdAt,
      );

      // Save to database
      if (mounted) {
        await context.read<DocumentProvider>().updateDocument(updatedDocument);

        if (mounted) {
          setState(() {
            _isSaving = false;
            _isEditing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Changes saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers to original values
        if (widget.document.documentType == 'invoice') {
          _initializeInvoiceControllers();
        } else {
          _editedData.forEach((key, value) {
            _controllers[key]?.text = _formatValue(value);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extraction Results'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.copy_all),
              onPressed: () {
                final jsonString = const JsonEncoder.withIndent('  ')
                    .convert(_editedData);
                _copyToClipboard(context, jsonString);
              },
              tooltip: 'Copy all data',
            ),
          ] else ...[
            TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              onPressed: _isSaving ? null : _toggleEditMode,
            ),
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: _isSaving ? null : _saveChanges,
            ),
          ],
        ],
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Saving changes...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.document.documentType == 'government_id'
                                    ? Icons.badge
                                    : Icons.receipt_long,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.document.documentType ==
                                              'government_id'
                                          ? 'Government ID'
                                          : 'Invoice',
                                      style:
                                          Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.document.fileName,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Extracted: ${_formatDate(widget.document.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.document.documentType == 'invoice'
                            ? 'Invoice Details'
                            : 'Extracted Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_isEditing)
                        Chip(
                          avatar: const Icon(Icons.edit, size: 16),
                          label: const Text('Editing Mode'),
                          backgroundColor: Colors.blue.shade100,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_editedData.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No data extracted from the document.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (widget.document.documentType == 'invoice')
                    _buildInvoiceTable()
                  else
                    _buildDataTable(),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInvoiceTable() {
    final lineItems = _editedData['line_items'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              dataRowMinHeight: 50,
              dataRowMaxHeight: 80,
              columnSpacing: 24,
              columns: [
                DataColumn(
                  label: Text(
                    'Seller Name',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Seller GSTIN',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Seller Contact',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Customer Name',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Invoice Date',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Bill Number',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                DataColumn(
                  numeric: true,
                  label: Text(
                    'Grand Total',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
              rows: [
                DataRow(
                  cells: [
                    DataCell(
                      _isEditing
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: TextField(
                                controller: _controllers['seller_name'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                _controllers['seller_name']?.text ?? 'N/A',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                    ),
                    DataCell(
                      _isEditing
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: TextField(
                                controller: _controllers['seller_gstin'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(_controllers['seller_gstin']?.text ?? 'N/A'),
                    ),
                    DataCell(
                      _isEditing
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: TextField(
                                controller: _controllers['seller_contact'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(_controllers['seller_contact']?.text ?? 'N/A'),
                    ),
                    DataCell(
                      _isEditing
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: TextField(
                                controller: _controllers['customer_name'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(_controllers['customer_name']?.text ?? 'N/A'),
                    ),
                    DataCell(
                      _isEditing
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: TextField(
                                controller: _controllers['invoice_date'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(_controllers['invoice_date']?.text ?? 'N/A'),
                    ),
                    DataCell(
                      _isEditing
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: TextField(
                                controller: _controllers['bill_number'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            )
                          : Text(_controllers['bill_number']?.text ?? 'N/A'),
                    ),
                    DataCell(
                      _isEditing
                          ? ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: TextField(
                                controller: _controllers['grand_total'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            )
                          : Text(
                              _controllers['grand_total']?.text ?? 'N/A',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (lineItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Line Items',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (lineItems.length > 1)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select an item to view details:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedLineItemIndex,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      hint: const Text('Choose a line item'),
                      items: List.generate(lineItems.length, (index) {
                        final item = lineItems[index] as Map?;
                        final description = item?['description']?.toString() ?? 'Item ${index + 1}';
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text('${index + 1}. $description'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _selectedLineItemIndex = value;
                        });
                      },
                    ),
                    if (_selectedLineItemIndex != null) ...[
                      const SizedBox(height: 16),
                      _buildLineItemDetails(lineItems[_selectedLineItemIndex!] as Map),
                    ],
                  ],
                ),
              ),
            )
          else
            _buildLineItemDetails(lineItems[0] as Map),
        ],
      ],
    );
  }

  Widget _buildLineItemDetails(Map lineItem) {
    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Description', lineItem['description']),
            _buildDetailRow('HSN Code', lineItem['hsn_code']),
            _buildDetailRow('Weight', lineItem['weight']),
            _buildDetailRow('Wastage %', lineItem['wastage_allowance_percentage']),
            _buildDetailRow('Rate', lineItem['rate']),
            _buildDetailRow('Making Charges %', lineItem['making_charges_percentage']),
            _buildDetailRow('Amount', lineItem['amount'], isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'N/A',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Card(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 32,
          ),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            columns: [
              DataColumn(
                label: Text(
                  'Field',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Value',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (!_isEditing)
                DataColumn(
                  label: Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
            rows: _editedData.entries.map((entry) {
              return DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(
                        _formatLabel(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  DataCell(
                    _isEditing
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 300,
                              minWidth: 200,
                            ),
                            child: TextField(
                              controller: _controllers[entry.key],
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              maxLines: null,
                            ),
                          )
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: SelectableText(
                              _formatValue(entry.value),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                  ),
                  if (!_isEditing)
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          _copyToClipboard(
                              context, _formatValue(entry.value));
                        },
                        tooltip: 'Copy',
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Safely get string value from map with default
  String _safeGetString(Map? data, String key, {String defaultValue = 'N/A'}) {
    if (data == null) return defaultValue;
    final value = data[key];
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Safely get numeric value from map with default
  dynamic _safeGetNumber(Map? data, String key, {String defaultValue = 'N/A'}) {
    if (data == null) return defaultValue;
    final value = data[key];
    if (value == null) return defaultValue;
    return value;
  }

  /// Flatten invoice data structure for better table display
  Map<String, dynamic> _flattenInvoiceData(Map<String, dynamic> data) {
    final flattened = <String, dynamic>{};

    // Handle double-nested extracted_data (backward compatibility)
    Map<String, dynamic> actualData = data;
    if (data.containsKey('extracted_data') && data['extracted_data'] is Map) {
      actualData = data['extracted_data'] as Map<String, dynamic>;
    }

    // Seller Info
    final sellerInfo = actualData['seller_info'] as Map?;
    flattened['Seller Name'] = _safeGetString(sellerInfo, 'name');
    flattened['Seller GSTIN'] = _safeGetString(sellerInfo, 'gstin');

    // Handle contact numbers array - take first value
    if (sellerInfo?['contact_numbers'] != null &&
        sellerInfo!['contact_numbers'] is List &&
        (sellerInfo['contact_numbers'] as List).isNotEmpty) {
      flattened['Seller Contact'] = (sellerInfo['contact_numbers'] as List).first.toString();
    } else {
      flattened['Seller Contact'] = 'N/A';
    }

    // Customer Info
    final customerInfo = actualData['customer_info'] as Map?;
    flattened['Customer Name'] = _safeGetString(customerInfo, 'name');
    flattened['Customer Address'] = _safeGetString(customerInfo, 'address');
    flattened['Customer Contact'] = _safeGetString(customerInfo, 'contact');
    flattened['Customer GSTIN'] = _safeGetString(customerInfo, 'gstin');

    // Invoice Details
    final invoiceDetails = actualData['invoice_details'] as Map?;
    flattened['Invoice Date'] = _safeGetString(invoiceDetails, 'date');
    flattened['Bill Number'] = _safeGetString(invoiceDetails, 'bill_no');
    flattened['Gold Price Per Unit'] = _safeGetNumber(invoiceDetails, 'gold_price_per_unit');

    // Line Items - summarize or show first item
    if (actualData['line_items'] != null && actualData['line_items'] is List) {
      final lineItems = actualData['line_items'] as List;
      if (lineItems.isNotEmpty) {
        final firstItem = lineItems.first as Map?;
        flattened['Item Description'] = _safeGetString(firstItem, 'description');
        flattened['HSN Code'] = _safeGetString(firstItem, 'hsn_code');
        flattened['Weight'] = _safeGetNumber(firstItem, 'weight');
        flattened['Wastage %'] = _safeGetNumber(firstItem, 'wastage_allowance_percentage');
        flattened['Rate'] = _safeGetNumber(firstItem, 'rate');
        flattened['Making Charges %'] = _safeGetNumber(firstItem, 'making_charges_percentage');
        flattened['Item Amount'] = _safeGetNumber(firstItem, 'amount');
      }
      // Add count of total items if more than one
      if (lineItems.length > 1) {
        flattened['Total Line Items'] = lineItems.length;
      }
    }

    // Summary
    final summary = actualData['summary'] as Map?;
    flattened['Sub Total'] = _safeGetNumber(summary, 'sub_total');
    flattened['Discount'] = _safeGetNumber(summary, 'discount');
    flattened['Taxable Amount'] = _safeGetNumber(summary, 'taxable_amount');
    flattened['SGST %'] = _safeGetNumber(summary, 'sgst_percentage');
    flattened['SGST Amount'] = _safeGetNumber(summary, 'sgst_amount');
    flattened['CGST %'] = _safeGetNumber(summary, 'cgst_percentage');
    flattened['CGST Amount'] = _safeGetNumber(summary, 'cgst_amount');
    flattened['Grand Total'] = _safeGetNumber(summary, 'grand_total');

    // Payment Details
    final paymentDetails = actualData['payment_details'] as Map?;
    flattened['Payment Cash'] = _safeGetNumber(paymentDetails, 'cash');
    flattened['Payment UPI'] = _safeGetNumber(paymentDetails, 'upi');
    flattened['Payment Card'] = _safeGetNumber(paymentDetails, 'card');

    // Total Amount in Words
    flattened['Amount in Words'] = _safeGetString(actualData, 'total_amount_in_words');

    return flattened;
  }

  String _formatLabel(String key) {
    // If key already has capital letters (flattened keys), return as is
    if (key.contains(RegExp(r'[A-Z]'))) {
      return key;
    }

    return key
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is Map || value is List) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
