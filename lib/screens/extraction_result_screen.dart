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

  @override
  void initState() {
    super.initState();
    _editedData = Map<String, dynamic>.from(widget.document.extractedData);

    // Flatten invoice data for better table display
    if (widget.document.documentType == 'invoice') {
      _editedData = _flattenInvoiceData(_editedData);
    }

    // Initialize controllers for each field
    _editedData.forEach((key, value) {
      _controllers[key] = TextEditingController(
        text: _formatValue(value),
      );
    });
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
      // Update edited data from controllers
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

      // Create updated document
      final updatedDocument = ExtractedDocument(
        id: widget.document.id,
        documentType: widget.document.documentType,
        fileName: widget.document.fileName,
        extractedData: _editedData,
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
        _editedData.forEach((key, value) {
          _controllers[key]?.text = _formatValue(value);
        });
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
                        'Extracted Information',
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

  /// Flatten invoice data structure for better table display
  Map<String, dynamic> _flattenInvoiceData(Map<String, dynamic> data) {
    final flattened = <String, dynamic>{};

    // Seller Info
    if (data['seller_info'] != null && data['seller_info'] is Map) {
      final sellerInfo = data['seller_info'] as Map;
      flattened['Seller Name'] = sellerInfo['name'];
      flattened['Seller GSTIN'] = sellerInfo['gstin'];

      // Handle contact numbers array - take first value
      if (sellerInfo['contact_numbers'] != null &&
          sellerInfo['contact_numbers'] is List &&
          (sellerInfo['contact_numbers'] as List).isNotEmpty) {
        flattened['Seller Contact'] = (sellerInfo['contact_numbers'] as List).first;
      } else {
        flattened['Seller Contact'] = sellerInfo['contact_numbers'];
      }
    }

    // Customer Info
    if (data['customer_info'] != null && data['customer_info'] is Map) {
      final customerInfo = data['customer_info'] as Map;
      flattened['Customer Name'] = customerInfo['name'];
      flattened['Customer Address'] = customerInfo['address'];
      flattened['Customer Contact'] = customerInfo['contact'];
      flattened['Customer GSTIN'] = customerInfo['gstin'];
    }

    // Invoice Details
    if (data['invoice_details'] != null && data['invoice_details'] is Map) {
      final invoiceDetails = data['invoice_details'] as Map;
      flattened['Invoice Date'] = invoiceDetails['date'];
      flattened['Bill Number'] = invoiceDetails['bill_no'];
      flattened['Gold Price Per Unit'] = invoiceDetails['gold_price_per_unit'];
    }

    // Line Items - summarize or show first item
    if (data['line_items'] != null && data['line_items'] is List) {
      final lineItems = data['line_items'] as List;
      if (lineItems.isNotEmpty) {
        final firstItem = lineItems.first as Map;
        flattened['Item Description'] = firstItem['description'];
        flattened['HSN Code'] = firstItem['hsn_code'];
        flattened['Weight'] = firstItem['weight'];
        flattened['Wastage %'] = firstItem['wastage_allowance_percentage'];
        flattened['Rate'] = firstItem['rate'];
        flattened['Making Charges %'] = firstItem['making_charges_percentage'];
        flattened['Item Amount'] = firstItem['amount'];
      }
      // Add count of total items if more than one
      if (lineItems.length > 1) {
        flattened['Total Line Items'] = lineItems.length;
      }
    }

    // Summary
    if (data['summary'] != null && data['summary'] is Map) {
      final summary = data['summary'] as Map;
      flattened['Sub Total'] = summary['sub_total'];
      flattened['Discount'] = summary['discount'];
      flattened['Taxable Amount'] = summary['taxable_amount'];
      flattened['SGST %'] = summary['sgst_percentage'];
      flattened['SGST Amount'] = summary['sgst_amount'];
      flattened['CGST %'] = summary['cgst_percentage'];
      flattened['CGST Amount'] = summary['cgst_amount'];
      flattened['Grand Total'] = summary['grand_total'];
    }

    // Payment Details
    if (data['payment_details'] != null && data['payment_details'] is Map) {
      final paymentDetails = data['payment_details'] as Map;
      flattened['Payment Cash'] = paymentDetails['cash'];
      flattened['Payment UPI'] = paymentDetails['upi'];
      flattened['Payment Card'] = paymentDetails['card'];
    }

    // Total Amount in Words
    if (data['total_amount_in_words'] != null) {
      flattened['Amount in Words'] = data['total_amount_in_words'];
    }

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
