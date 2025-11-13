import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../models/extracted_document.dart';

/// Widget to display and edit invoice line items
class InvoiceLineItemsWidget extends StatefulWidget {
  final ExtractedDocument document;
  final VoidCallback onSaved;

  const InvoiceLineItemsWidget({
    super.key,
    required this.document,
    required this.onSaved,
  });

  @override
  State<InvoiceLineItemsWidget> createState() => _InvoiceLineItemsWidgetState();
}

class _InvoiceLineItemsWidgetState extends State<InvoiceLineItemsWidget> {
  late List<Map<String, dynamic>> _lineItems;
  late Map<String, dynamic> _summary;
  bool _isEditing = false;
  bool _isSaving = false;
  final Map<String, Map<String, TextEditingController>> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Handle double-nested extracted_data (backward compatibility)
    final rawData = widget.document.extractedData;
    final data = rawData.containsKey('extracted_data') && rawData['extracted_data'] is Map
        ? rawData['extracted_data'] as Map<String, dynamic>
        : rawData;

    _lineItems = List<Map<String, dynamic>>.from(
      (data['line_items'] as List?)?.map((item) => Map<String, dynamic>.from(item as Map)) ?? []
    );
    _summary = Map<String, dynamic>.from(data['summary'] as Map? ?? {});
    _initializeControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    for (int i = 0; i < _lineItems.length; i++) {
      _controllers['$i'] = {
        'description': TextEditingController(text: _lineItems[i]['description']?.toString() ?? ''),
        'weight': TextEditingController(text: _lineItems[i]['weight']?.toString() ?? '0'),
        'wastage_allowance_percentage': TextEditingController(text: _lineItems[i]['wastage_allowance_percentage']?.toString() ?? '0'),
        'rate': TextEditingController(text: _lineItems[i]['rate']?.toString() ?? '0'),
        'making_charges_percentage': TextEditingController(text: _lineItems[i]['making_charges_percentage']?.toString() ?? '0'),
      };
    }
  }

  void _disposeControllers() {
    for (var itemControllers in _controllers.values) {
      for (var controller in itemControllers.values) {
        controller.dispose();
      }
    }
  }

  double _calculateItemAmount(int index) {
    try {
      final weight = double.tryParse(_controllers['$index']!['weight']!.text) ?? 0;
      final rate = double.tryParse(_controllers['$index']!['rate']!.text) ?? 0;
      final waPercentage = double.tryParse(_controllers['$index']!['wastage_allowance_percentage']!.text) ?? 0;
      final mcPercentage = double.tryParse(_controllers['$index']!['making_charges_percentage']!.text) ?? 0;

      // Calculate: weight * rate * (1 + wa%) * (1 + mc%)
      double amount = weight * rate;
      amount = amount * (1 + waPercentage / 100);
      amount = amount * (1 + mcPercentage / 100);

      return amount;
    } catch (e) {
      return 0;
    }
  }

  void _recalculateSummary() {
    double subTotal = 0;
    for (int i = 0; i < _lineItems.length; i++) {
      subTotal += _calculateItemAmount(i);
    }

    final discount = _summary['discount'] ?? 0;
    final taxableAmount = subTotal - (discount is num ? discount : 0);

    final sgstPercentage = _summary['sgst_percentage'] ?? 0;
    final cgstPercentage = _summary['cgst_percentage'] ?? 0;

    final sgstAmount = taxableAmount * (sgstPercentage is num ? sgstPercentage : 0) / 100;
    final cgstAmount = taxableAmount * (cgstPercentage is num ? cgstPercentage : 0) / 100;

    final grandTotal = taxableAmount + sgstAmount + cgstAmount;

    setState(() {
      _summary = {
        'sub_total': subTotal,
        'discount': discount,
        'taxable_amount': taxableAmount,
        'sgst_percentage': sgstPercentage,
        'sgst_amount': sgstAmount,
        'cgst_percentage': cgstPercentage,
        'cgst_amount': cgstAmount,
        'grand_total': grandTotal,
      };
    });
  }

  void _addLineItem() {
    setState(() {
      final newIndex = _lineItems.length;
      _lineItems.add({
        'description': '',
        'weight': 0,
        'wastage_allowance_percentage': 0,
        'rate': 0,
        'making_charges_percentage': 0,
        'amount': 0,
      });
      _controllers['$newIndex'] = {
        'description': TextEditingController(),
        'weight': TextEditingController(text: '0'),
        'wastage_allowance_percentage': TextEditingController(text: '0'),
        'rate': TextEditingController(text: '0'),
        'making_charges_percentage': TextEditingController(text: '0'),
      };
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      // Dispose controllers for this item
      for (var controller in _controllers['$index']!.values) {
        controller.dispose();
      }
      _controllers.remove('$index');
      _lineItems.removeAt(index);

      // Re-index remaining controllers
      final newControllers = <String, Map<String, TextEditingController>>{};
      for (int i = 0; i < _lineItems.length; i++) {
        final oldIndex = i < index ? i : i + 1;
        newControllers['$i'] = _controllers['$oldIndex']!;
      }
      _controllers.clear();
      _controllers.addAll(newControllers);

      _recalculateSummary();
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      // Update line items with calculated amounts
      for (int i = 0; i < _lineItems.length; i++) {
        _lineItems[i] = {
          'description': _controllers['$i']!['description']!.text,
          'weight': double.tryParse(_controllers['$i']!['weight']!.text) ?? 0,
          'wastage_allowance_percentage': double.tryParse(_controllers['$i']!['wastage_allowance_percentage']!.text) ?? 0,
          'rate': double.tryParse(_controllers['$i']!['rate']!.text) ?? 0,
          'making_charges_percentage': double.tryParse(_controllers['$i']!['making_charges_percentage']!.text) ?? 0,
          'amount': _calculateItemAmount(i),
          'hsn_code': _lineItems[i]['hsn_code'],
        };
      }

      // Create updated document
      final updatedData = Map<String, dynamic>.from(widget.document.extractedData);
      updatedData['line_items'] = _lineItems;
      updatedData['summary'] = _summary;

      final updatedDocument = ExtractedDocument(
        id: widget.document.id,
        documentType: widget.document.documentType,
        fileName: widget.document.fileName,
        extractedData: updatedData,
        createdAt: widget.document.createdAt,
      );

      // Save to backend
      final provider = Provider.of<DocumentProvider>(context, listen: false);
      await provider.updateDocument(updatedDocument);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
        setState(() => _isEditing = false);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Line Items (${_lineItems.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_isEditing) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                        onPressed: _addLineItem,
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _initializeControllers();
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                        label: const Text('Save'),
                        onPressed: _isSaving ? null : _saveChanges,
                      ),
                    ] else
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                dataRowMinHeight: 50,
                columns: [
                  const DataColumn(label: Text('Description')),
                  const DataColumn(label: Text('Weight (g)')),
                  const DataColumn(label: Text('W/A %')),
                  const DataColumn(label: Text('Rate')),
                  const DataColumn(label: Text('M/C %')),
                  const DataColumn(label: Text('Amount')),
                  if (_isEditing) const DataColumn(label: Text('Actions')),
                ],
                rows: List.generate(_lineItems.length, (index) {
                  return DataRow(
                    cells: [
                      DataCell(
                        _isEditing
                          ? SizedBox(
                              width: 150,
                              child: TextField(
                                controller: _controllers['$index']!['description'],
                                decoration: const InputDecoration(isDense: true),
                              ),
                            )
                          : Text(_lineItems[index]['description']?.toString() ?? 'N/A'),
                      ),
                      DataCell(
                        _isEditing
                          ? SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _controllers['$index']!['weight'],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                decoration: const InputDecoration(isDense: true),
                                onChanged: (_) => _recalculateSummary(),
                              ),
                            )
                          : Text(_lineItems[index]['weight']?.toString() ?? '0'),
                      ),
                      DataCell(
                        _isEditing
                          ? SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _controllers['$index']!['wastage_allowance_percentage'],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                decoration: const InputDecoration(isDense: true),
                                onChanged: (_) => _recalculateSummary(),
                              ),
                            )
                          : Text(_lineItems[index]['wastage_allowance_percentage']?.toString() ?? '0'),
                      ),
                      DataCell(
                        _isEditing
                          ? SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _controllers['$index']!['rate'],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                decoration: const InputDecoration(isDense: true),
                                onChanged: (_) => _recalculateSummary(),
                              ),
                            )
                          : Text(_lineItems[index]['rate']?.toString() ?? '0'),
                      ),
                      DataCell(
                        _isEditing
                          ? SizedBox(
                              width: 60,
                              child: TextField(
                                controller: _controllers['$index']!['making_charges_percentage'],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                decoration: const InputDecoration(isDense: true),
                                onChanged: (_) => _recalculateSummary(),
                              ),
                            )
                          : Text(_lineItems[index]['making_charges_percentage']?.toString() ?? '0'),
                      ),
                      DataCell(
                        Text(
                          _isEditing
                            ? _calculateItemAmount(index).toStringAsFixed(2)
                            : (_lineItems[index]['amount']?.toString() ?? '0'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_isEditing)
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => _removeLineItem(index),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            _buildSummarySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
          },
          children: [
            _buildSummaryRow('Sub Total', _summary['sub_total']),
            _buildSummaryRow('Discount', _summary['discount']),
            _buildSummaryRow('Taxable Amount', _summary['taxable_amount']),
            _buildSummaryRow('SGST (${_summary['sgst_percentage']}%)', _summary['sgst_amount']),
            _buildSummaryRow('CGST (${_summary['cgst_percentage']}%)', _summary['cgst_amount']),
            _buildSummaryRow('Grand Total', _summary['grand_total'], isTotal: true),
          ],
        ),
      ],
    );
  }

  TableRow _buildSummaryRow(String label, dynamic value, {bool isTotal = false}) {
    final displayValue = value is num ? value.toStringAsFixed(2) : (value?.toString() ?? 'N/A');
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            displayValue,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
