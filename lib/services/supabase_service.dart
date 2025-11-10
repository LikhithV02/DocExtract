import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/extracted_document.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Save extracted document to Supabase
  Future<void> saveExtractedDocument(ExtractedDocument document) async {
    try {
      await _client.from('extracted_documents').insert(document.toJson());
    } catch (e) {
      throw Exception('Error saving document: $e');
    }
  }

  /// Get all extracted documents
  Future<List<ExtractedDocument>> getAllDocuments() async {
    try {
      final response = await _client
          .from('extracted_documents')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((doc) => ExtractedDocument.fromJson(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching documents: $e');
    }
  }

  /// Get documents by type
  Future<List<ExtractedDocument>> getDocumentsByType(String type) async {
    try {
      final response = await _client
          .from('extracted_documents')
          .select()
          .eq('document_type', type)
          .order('created_at', ascending: false);

      return (response as List)
          .map((doc) => ExtractedDocument.fromJson(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching documents by type: $e');
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String id) async {
    try {
      await _client.from('extracted_documents').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }

  /// Get single document by ID
  Future<ExtractedDocument?> getDocumentById(String id) async {
    try {
      final response =
          await _client.from('extracted_documents').select().eq('id', id).single();

      return ExtractedDocument.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching document: $e');
    }
  }
}
