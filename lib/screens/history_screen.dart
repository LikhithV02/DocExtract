import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/document_provider.dart';
import '../models/extracted_document.dart';
import 'extraction_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'all',
                  label: Text('All'),
                  icon: Icon(Icons.all_inclusive),
                ),
                ButtonSegment(
                  value: 'government_id',
                  label: Text('IDs'),
                  icon: Icon(Icons.badge),
                ),
                ButtonSegment(
                  value: 'invoice',
                  label: Text('Invoices'),
                  icon: Icon(Icons.receipt_long),
                ),
              ],
              selected: {_filterType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _filterType = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<DocumentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${provider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadDocuments(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final documents = _filterType == 'all'
                    ? provider.documents
                    : provider.getDocumentsByType(_filterType);

                if (documents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No documents yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start by extracting your first document',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadDocuments(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      return _DocumentCard(
                        document: document,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ExtractionResultScreen(document: document),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(context, document),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ExtractedDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<DocumentProvider>().deleteDocument(document.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting document: $e')),
          );
        }
      }
    }
  }
}

class _DocumentCard extends StatefulWidget {
  final ExtractedDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<_DocumentCard> {
  bool _isExpanded = false;

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGovernmentId = widget.document.documentType == 'government_id';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isGovernmentId
                          ? Colors.blue.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isGovernmentId ? Icons.badge : Icons.receipt_long,
                      color: isGovernmentId ? Colors.blue : Colors.green,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.document.fileName,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isGovernmentId ? 'Government ID' : 'Invoice',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(widget.document.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: widget.onDelete,
                    color: Colors.red,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Extracted Data',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.copy_all, size: 16),
                            label: const Text('Copy All'),
                            onPressed: () {
                              final jsonString = const JsonEncoder.withIndent('  ')
                                  .convert(widget.document.extractedData);
                              _copyToClipboard(context, jsonString);
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('View Details'),
                            onPressed: widget.onTap,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.document.extractedData.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No data extracted',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ),
                    )
                  else
                    _buildDataTable(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    // Flatten invoice data for better display
    final displayData = widget.document.documentType == 'invoice'
        ? _flattenInvoiceData(widget.document.extractedData)
        : widget.document.extractedData;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          Theme.of(context).colorScheme.primary.withOpacity(0.1),
        ),
        dataRowMinHeight: 40,
        dataRowMaxHeight: 80,
        columns: [
          DataColumn(
            label: Text(
              'Field',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          DataColumn(
            label: Text(
              'Value',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          DataColumn(
            label: Text(
              'Actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
        rows: displayData.entries.map((entry) {
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: SelectableText(
                    _formatValue(entry.value),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    _copyToClipboard(context, _formatValue(entry.value));
                  },
                  tooltip: 'Copy',
                ),
              ),
            ],
          );
        }).toList(),
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
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
