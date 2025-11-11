import 'package:flutter/foundation.dart';
import '../models/extracted_document.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class DocumentProvider with ChangeNotifier {
  final ApiService _apiService;
  final WebSocketService _wsService;

  List<ExtractedDocument> _documents = [];
  bool _isLoading = false;
  String? _error;
  Map<String, int>? _stats;

  List<ExtractedDocument> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int>? get stats => _stats;

  DocumentProvider({
    ApiService? apiService,
    WebSocketService? wsService,
  })  : _apiService = apiService ?? ApiService(),
        _wsService = wsService ?? WebSocketService() {
    _initWebSocket();
  }

  /// Initialize WebSocket connection and listen for events
  void _initWebSocket() {
    try {
      _wsService.connect();

      _wsService.events.listen((event) {
        switch (event.type) {
          case DocumentEventType.insert:
            final doc = event.document;
            if (doc != null) {
              // Check if document already exists
              final exists = _documents.any((d) => d.id == doc.id);
              if (!exists) {
                _documents.insert(0, doc);
                notifyListeners();
                debugPrint('Document inserted via WebSocket: ${doc.id}');
              }
            }
            break;

          case DocumentEventType.update:
            final doc = event.document;
            if (doc != null) {
              final index = _documents.indexWhere((d) => d.id == doc.id);
              if (index != -1) {
                _documents[index] = doc;
                notifyListeners();
                debugPrint('Document updated via WebSocket: ${doc.id}');
              }
            }
            break;

          case DocumentEventType.delete:
            final docId = event.documentId;
            if (docId != null) {
              _documents.removeWhere((d) => d.id == docId);
              notifyListeners();
              debugPrint('Document deleted via WebSocket: $docId');
            }
            break;
        }
      }, onError: (error) {
        debugPrint('WebSocket error: $error');
      });
    } catch (e) {
      debugPrint('Error initializing WebSocket: $e');
    }
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }

  /// Load all documents from the backend
  Future<void> loadDocuments({String? documentType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _documents = await _apiService.getDocuments(
        documentType: documentType,
        limit: 100,
        offset: 0,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error loading documents: $e');
    }
  }

  /// Load document statistics
  Future<void> loadStats() async {
    try {
      _stats = await _apiService.getStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  /// Extract and save a document
  Future<ExtractedDocument> extractAndSaveDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String documentType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Extract document using LlamaParse
      debugPrint('Extracting document: $fileName');
      final extractionResult = await _apiService.extractDocument(
        fileBytes: fileBytes,
        fileName: fileName,
        documentType: documentType,
      );

      // Step 2: Create document object
      final document = ExtractedDocument(
        id: '', // Will be assigned by server
        documentType: documentType,
        fileName: fileName,
        extractedData: extractionResult['extracted_data'] as Map<String, dynamic>,
        createdAt: DateTime.now(),
      );

      // Step 3: Save to database
      debugPrint('Saving document to database');
      final savedDocument = await _apiService.saveDocument(document);

      // Step 4: Add to local list (WebSocket will also send update, but this is immediate)
      final exists = _documents.any((d) => d.id == savedDocument.id);
      if (!exists) {
        _documents.insert(0, savedDocument);
      }

      _isLoading = false;
      notifyListeners();

      // Refresh stats
      await loadStats();

      return savedDocument;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('Error extracting and saving document: $e');
      rethrow;
    }
  }

  /// Add a pre-extracted document (for backward compatibility)
  Future<void> addDocument(ExtractedDocument document) async {
    try {
      final savedDocument = await _apiService.saveDocument(document);

      final exists = _documents.any((d) => d.id == savedDocument.id);
      if (!exists) {
        _documents.insert(0, savedDocument);
        notifyListeners();
      }

      // Refresh stats
      await loadStats();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error adding document: $e');
      rethrow;
    }
  }

  /// Delete a document
  Future<void> deleteDocument(String id) async {
    try {
      final success = await _apiService.deleteDocument(id);

      if (success) {
        _documents.removeWhere((doc) => doc.id == id);
        notifyListeners();

        // Refresh stats
        await loadStats();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }

  /// Get document by ID
  Future<ExtractedDocument?> getDocumentById(String id) async {
    try {
      // Check local cache first
      final cachedDoc = _documents.firstWhere(
        (doc) => doc.id == id,
        orElse: () => throw Exception('Not found in cache'),
      );
      return cachedDoc;
    } catch (e) {
      // Fetch from server if not in cache
      try {
        return await _apiService.getDocumentById(id);
      } catch (e) {
        debugPrint('Error getting document by ID: $e');
        return null;
      }
    }
  }

  /// Get documents by type
  List<ExtractedDocument> getDocumentsByType(String type) {
    return _documents.where((doc) => doc.documentType == type).toList();
  }

  /// Get recent documents (last N)
  List<ExtractedDocument> getRecentDocuments(int count) {
    return _documents.take(count).toList();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Manually reconnect WebSocket
  void reconnectWebSocket() {
    _wsService.reconnect();
  }

  /// Get WebSocket connection status
  bool get isWebSocketConnected => _wsService.isConnected;
}
