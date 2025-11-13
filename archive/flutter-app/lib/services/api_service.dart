import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/extracted_document.dart';

/// Service for interacting with DocExtract backend API
class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: ApiConfig.requestTimeout,
        receiveTimeout: ApiConfig.requestTimeout,
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptor for logging (optional, can be removed in production)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false, // Set to false to avoid logging large base64 data
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Extract data from a document using LlamaParse
  ///
  /// [fileBytes] - Raw file bytes to extract
  /// [fileName] - Name of the file
  /// [documentType] - Type of document ('government_id' or 'invoice')
  ///
  /// Returns a Map containing the extracted data
  Future<Map<String, dynamic>> extractDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String documentType,
  }) async {
    try {
      // Convert file bytes to base64
      final base64Data = base64Encode(fileBytes);

      // Prepare request payload
      final payload = {
        'file_data': base64Data,
        'file_name': fileName,
        'document_type': documentType,
      };

      // Make API request
      final response = await _dio.post(
        ApiConfig.extractEndpoint,
        data: payload,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Extraction failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Save an extracted document to the database
  ///
  /// [document] - ExtractedDocument to save
  ///
  /// Returns the saved ExtractedDocument with server-assigned ID
  Future<ExtractedDocument> saveDocument(ExtractedDocument document) async {
    try {
      final payload = {
        'document_type': document.documentType,
        'file_name': document.fileName,
        'extracted_data': document.extractedData,
      };

      final response = await _dio.post(
        ApiConfig.documentsEndpoint,
        data: payload,
      );

      if (response.statusCode == 201) {
        return ExtractedDocument.fromJson(response.data);
      } else {
        throw Exception('Failed to save document: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get all documents with optional filtering
  ///
  /// [documentType] - Filter by document type (optional)
  /// [limit] - Maximum number of documents to return (default 100)
  /// [offset] - Number of documents to skip (default 0)
  ///
  /// Returns a list of ExtractedDocument objects
  Future<List<ExtractedDocument>> getDocuments({
    String? documentType,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      if (documentType != null) {
        queryParams['document_type'] = documentType;
      }

      final response = await _dio.get(
        ApiConfig.documentsEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final documents = data['documents'] as List;
        return documents
            .map((doc) => ExtractedDocument.fromJson(doc))
            .toList();
      } else {
        throw Exception('Failed to fetch documents: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get a single document by ID
  ///
  /// [id] - Document ID
  ///
  /// Returns the ExtractedDocument or throws if not found
  Future<ExtractedDocument> getDocumentById(String id) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.documentsEndpoint}/$id',
      );

      if (response.statusCode == 200) {
        return ExtractedDocument.fromJson(response.data);
      } else {
        throw Exception('Document not found');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update an existing document
  ///
  /// [document] - ExtractedDocument to update
  ///
  /// Returns the updated ExtractedDocument
  Future<ExtractedDocument> updateDocument(ExtractedDocument document) async {
    try {
      final payload = {
        'document_type': document.documentType,
        'file_name': document.fileName,
        'extracted_data': document.extractedData,
      };

      final response = await _dio.put(
        '${ApiConfig.documentsEndpoint}/${document.id}',
        data: payload,
      );

      if (response.statusCode == 200) {
        return ExtractedDocument.fromJson(response.data);
      } else {
        throw Exception('Failed to update document: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a document by ID
  ///
  /// [id] - Document ID
  ///
  /// Returns true if deleted successfully
  Future<bool> deleteDocument(String id) async {
    try {
      final response = await _dio.delete(
        '${ApiConfig.documentsEndpoint}/$id',
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get document statistics
  ///
  /// Returns a Map containing total, government_id, and invoice counts
  Future<Map<String, int>> getStats() async {
    try {
      final response = await _dio.get(ApiConfig.statsEndpoint);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return {
          'total': data['total'] as int,
          'government_id': data['government_id'] as int,
          'invoice': data['invoice'] as int,
        };
      } else {
        throw Exception('Failed to fetch stats: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors and convert to meaningful exceptions
  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please check your internet connection.');
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['detail'] ?? 'Unknown error';

      if (statusCode == 404) {
        return Exception('Resource not found');
      } else if (statusCode == 400) {
        return Exception('Invalid request: $message');
      } else if (statusCode == 500) {
        return Exception('Server error: $message');
      }

      return Exception('Request failed ($statusCode): $message');
    } else if (e.type == DioExceptionType.unknown) {
      return Exception('Network error. Please check your connection.');
    }

    return Exception('Unknown error: ${e.message}');
  }
}
