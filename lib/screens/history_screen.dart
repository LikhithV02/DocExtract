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

                // Show table view for invoices
                if (_filterType == 'invoice' ||
                    (_filterType == 'all' && documents.any((d) => d.documentType == 'invoice'))) {
                  final invoices = documents.where((d) => d.documentType == 'invoice').toList();
                  if (invoices.isNotEmpty) {
                    return _InvoiceTableView(
                      invoices: invoices,
                      onDelete: (document) => _confirmDelete(context, document),
                      onView: (document) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ExtractionResultScreen(document: document),
                          ),
                        );
                      },
                    );
                  }
                }

                // Show card view for government IDs or mixed view
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

class _InvoiceTableView extends StatelessWidget {
  final List<ExtractedDocument> invoices;
  final Function(ExtractedDocument) onDelete;
  final Function(ExtractedDocument) onView;

  const _InvoiceTableView({
    required this.invoices,
    required this.onDelete,
    required this.onView,
  });

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invoice History (${invoices.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_all),
                onPressed: () {
                  final allData = invoices.map((inv) => inv.extractedData).toList();
                  final jsonString = const JsonEncoder.withIndent('  ').convert(allData);
                  _copyToClipboard(context, jsonString);
                },
                tooltip: 'Copy all invoice data',
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      'Time',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
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
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
                rows: invoices.map((invoice) {
                  final flatData = _flattenInvoiceData(invoice.extractedData);
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          _formatDate(invoice.createdAt),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Text(
                            flatData['Seller Name']?.toString() ?? 'N/A',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(flatData['Seller GSTIN']?.toString() ?? 'N/A'),
                      ),
                      DataCell(
                        Text(flatData['Seller Contact']?.toString() ?? 'N/A'),
                      ),
                      DataCell(
                        Text(flatData['Customer Name']?.toString() ?? 'N/A'),
                      ),
                      DataCell(
                        Text(flatData['Invoice Date']?.toString() ?? 'N/A'),
                      ),
                      DataCell(
                        Text(flatData['Bill Number']?.toString() ?? 'N/A'),
                      ),
                      DataCell(
                        Text(
                          flatData['Grand Total']?.toString() ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 18),
                              onPressed: () => onView(invoice),
                              tooltip: 'View Details',
                              color: Colors.blue,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => onDelete(invoice),
                              tooltip: 'Delete',
                              color: Colors.red,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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

    // Summary
    if (data['summary'] != null && data['summary'] is Map) {
      final summary = data['summary'] as Map;
      flattened['Grand Total'] = summary['grand_total'];
    }

    return flattened;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _DocumentCard extends StatelessWidget {
  final ExtractedDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isGovernmentId = document.documentType == 'government_id';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      document.fileName,
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
                      _formatDate(document.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.red,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
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
