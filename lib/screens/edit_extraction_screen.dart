import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/extracted_document.dart';
import '../providers/document_provider.dart';

class EditExtractionScreen extends StatefulWidget {
  final ExtractedDocument document;
  final bool isNewDocument;

  const EditExtractionScreen({
    super.key,
    required this.document,
    this.isNewDocument = true,
  });

  @override
  State<EditExtractionScreen> createState() => _EditExtractionScreenState();
}

class _EditExtractionScreenState extends State<EditExtractionScreen> {
  late Map<String, dynamic> _editedData;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editedData = Map<String, dynamic>.from(widget.document.extractedData);

    // Initialize controllers for each field
    _editedData.forEach((key, value) {
      if (value is! List && value is! Map) {
        _controllers[key] = TextEditingController(
          text: value?.toString() ?? '',
        );
      }
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveDocument() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Update edited data from controllers
      _controllers.forEach((key, controller) {
        final originalValue = _editedData[key];
        if (originalValue is num) {
          _editedData[key] = num.tryParse(controller.text) ?? controller.text;
        } else {
          _editedData[key] = controller.text;
        }
      });

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
        await context.read<DocumentProvider>().addDocument(updatedDocument);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to home
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewDocument ? 'Review & Edit' : 'Edit Document'),
        actions: [
          if (!_isSaving)
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('SAVE'),
              onPressed: _saveDocument,
            ),
        ],
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Saving document...'),
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
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note,
                            color: Colors.blue.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review Extracted Data',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Edit any field before saving to database',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.document.fileName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._editedData.entries.map((entry) {
                    if (entry.value is List) {
                      return _buildListField(entry.key, entry.value as List);
                    } else if (entry.value is Map) {
                      return _buildMapField(entry.key, entry.value as Map);
                    } else {
                      return _buildTextField(entry.key);
                    }
                  }),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Save to Database',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _isSaving ? null : _saveDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () {
                              Navigator.popUntil(
                                  context, (route) => route.isFirst);
                            },
                      style: OutlinedButton.styleFrom(
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

  Widget _buildTextField(String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: _formatLabel(key),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        maxLines: null,
        keyboardType: _getKeyboardType(_editedData[key]),
      ),
    );
  }

  Widget _buildListField(String key, List value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          _formatLabel(key),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              const JsonEncoder.withIndent('  ').convert(value),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapField(String key, Map value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          _formatLabel(key),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              const JsonEncoder.withIndent('  ').convert(value),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String key) {
    return key
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  TextInputType _getKeyboardType(dynamic value) {
    if (value is num) {
      return TextInputType.number;
    }
    return TextInputType.text;
  }
}
