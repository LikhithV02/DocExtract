import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../models/extracted_document.dart';
import 'edit_extraction_screen.dart';

class DocumentTypeSelectionScreen extends StatefulWidget {
  final File? file;
  final Uint8List? fileBytes;
  final String fileName;

  const DocumentTypeSelectionScreen({
    super.key,
    required this.file,
    required this.fileBytes,
    required this.fileName,
  });

  @override
  State<DocumentTypeSelectionScreen> createState() =>
      _DocumentTypeSelectionScreenState();
}

class _DocumentTypeSelectionScreenState
    extends State<DocumentTypeSelectionScreen> {
  String? _selectedType;
  bool _isProcessing = false;

  Future<void> _processDocument() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document type')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final apiService = ApiService();

      // Get file bytes
      Uint8List bytes;
      if (widget.fileBytes != null) {
        bytes = widget.fileBytes!;
      } else if (widget.file != null) {
        bytes = await widget.file!.readAsBytes();
      } else {
        throw Exception('No file provided');
      }

      // Extract data using backend API
      final extractedData = await apiService.extractDocument(
        fileBytes: bytes,
        fileName: widget.fileName,
        documentType: _selectedType!,
      );

      // Create document model
      final document = ExtractedDocument(
        id: const Uuid().v4(),
        documentType: _selectedType!,
        fileName: widget.fileName,
        extractedData: extractedData,
        createdAt: DateTime.now(),
      );

      // Navigate to edit screen for user to review and edit
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EditExtractionScreen(
              document: document,
              isNewDocument: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to process document: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Document Type'),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Processing document...'),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few moments',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'File: ${widget.fileName}',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'What type of document is this?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _DocumentTypeCard(
                    icon: Icons.badge,
                    title: 'Government ID',
                    description:
                        'Passport, Driver\'s License, National ID, etc.',
                    isSelected: _selectedType == 'government_id',
                    onTap: () {
                      setState(() {
                        _selectedType = 'government_id';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _DocumentTypeCard(
                    icon: Icons.receipt_long,
                    title: 'Invoice',
                    description: 'Bills, Receipts, Purchase Orders, etc.',
                    isSelected: _selectedType == 'invoice',
                    onTap: () {
                      setState(() {
                        _selectedType = 'invoice';
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _selectedType != null ? _processDocument : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Extract Information',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DocumentTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _DocumentTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 48,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
