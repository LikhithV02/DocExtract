import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/extracted_document.dart';
import '../services/supabase_service.dart';

class DocumentProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  RealtimeChannel? _realtimeChannel;

  List<ExtractedDocument> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<ExtractedDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize real-time sync
  void initRealtimeSync() {
    final supabase = Supabase.instance.client;

    _realtimeChannel = supabase
        .channel('extracted_documents_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'extracted_documents',
          callback: (payload) {
            try {
              final newDoc = ExtractedDocument.fromJson(payload.newRecord);
              // Check if document already exists
              final exists = _documents.any((doc) => doc.id == newDoc.id);
              if (!exists) {
                _documents.insert(0, newDoc);
                notifyListeners();
              }
            } catch (e) {
              debugPrint('Error processing realtime insert: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'extracted_documents',
          callback: (payload) {
            try {
              final updatedDoc = ExtractedDocument.fromJson(payload.newRecord);
              final index = _documents.indexWhere((doc) => doc.id == updatedDoc.id);
              if (index != -1) {
                _documents[index] = updatedDoc;
                notifyListeners();
              }
            } catch (e) {
              debugPrint('Error processing realtime update: $e');
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'extracted_documents',
          callback: (payload) {
            try {
              final deletedId = payload.oldRecord['id'] as String;
              _documents.removeWhere((doc) => doc.id == deletedId);
              notifyListeners();
            } catch (e) {
              debugPrint('Error processing realtime delete: $e');
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  /// Load all documents from Supabase
  Future<void> loadDocuments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _documents = await _supabaseService.getAllDocuments();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new document
  Future<void> addDocument(ExtractedDocument document) async {
    try {
      await _supabaseService.saveExtractedDocument(document);
      _documents.insert(0, document);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String id) async {
    try {
      await _supabaseService.deleteDocument(id);
      _documents.removeWhere((doc) => doc.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get documents by type
  List<ExtractedDocument> getDocumentsByType(String type) {
    return _documents.where((doc) => doc.documentType == type).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
