import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'document_type_selection_screen.dart';
import 'history_screen.dart';
import '../providers/document_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load documents (WebSocket sync is initialized automatically)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DocumentProvider>();
      provider.loadDocuments();
    });
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        _navigateToDocumentTypeSelection(
          file: File(photo.path),
          fileBytes: await photo.readAsBytes(),
          fileName: photo.name,
        );
      }
    } catch (e) {
      _showErrorDialog('Error accessing camera: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        _navigateToDocumentTypeSelection(
          file: File(image.path),
          fileBytes: await image.readAsBytes(),
          fileName: image.name,
        );
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && mounted) {
        final file = result.files.first;
        _navigateToDocumentTypeSelection(
          file: kIsWeb ? null : File(file.path!),
          fileBytes: file.bytes,
          fileName: file.name,
        );
      }
    } catch (e) {
      _showErrorDialog('Error picking file: $e');
    }
  }

  void _navigateToDocumentTypeSelection({
    required File? file,
    required Uint8List? fileBytes,
    required String fileName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentTypeSelectionScreen(
          file: file,
          fileBytes: fileBytes,
          fileName: fileName,
        ),
      ),
    );
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DocExtract'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
            tooltip: 'View History',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.document_scanner,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Extract Information from Documents',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Capture or upload government IDs and invoices',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: kIsWeb ? 400 : double.infinity,
                ),
                child: Column(
                  children: [
                    _ActionButton(
                      icon: Icons.camera_alt,
                      label: 'Take Photo',
                      onPressed: _pickImageFromCamera,
                    ),
                    const SizedBox(height: 16),
                    if (!kIsWeb) ...[
                      _ActionButton(
                        icon: Icons.photo_library,
                        label: 'Choose from Gallery',
                        onPressed: _pickImageFromGallery,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _ActionButton(
                      icon: Icons.upload_file,
                      label: 'Upload PDF or Image',
                      onPressed: _pickFile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Consumer<DocumentProvider>(
                builder: (context, provider, child) {
                  return Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatCard(
                                icon: Icons.description,
                                label: 'Total Documents',
                                value: provider.documents.length.toString(),
                              ),
                              _StatCard(
                                icon: Icons.badge,
                                label: 'Government IDs',
                                value: provider
                                    .getDocumentsByType('government_id')
                                    .length
                                    .toString(),
                              ),
                              _StatCard(
                                icon: Icons.receipt_long,
                                label: 'Invoices',
                                value: provider
                                    .getDocumentsByType('invoice')
                                    .length
                                    .toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
