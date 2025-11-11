import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../models/extracted_document.dart';

/// Types of document events from WebSocket
enum DocumentEventType {
  insert,
  update,
  delete,
}

/// Document event received from WebSocket
class DocumentEvent {
  final DocumentEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  DocumentEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory DocumentEvent.fromJson(Map<String, dynamic> json) {
    DocumentEventType type;
    switch (json['type'].toString().toUpperCase()) {
      case 'INSERT':
        type = DocumentEventType.insert;
        break;
      case 'UPDATE':
        type = DocumentEventType.update;
        break;
      case 'DELETE':
        type = DocumentEventType.delete;
        break;
      default:
        type = DocumentEventType.insert;
    }

    return DocumentEvent(
      type: type,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Get the document from event data (for INSERT/UPDATE events)
  ExtractedDocument? get document {
    if (type == DocumentEventType.delete) return null;
    try {
      return ExtractedDocument.fromJson(data);
    } catch (e) {
      print('Error parsing document from event: $e');
      return null;
    }
  }

  /// Get the document ID (for DELETE events)
  String? get documentId {
    if (type == DocumentEventType.delete) {
      return data['id'] as String?;
    }
    return document?.id;
  }
}

/// WebSocket service for real-time document updates
class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<DocumentEvent> _eventController =
      StreamController<DocumentEvent>.broadcast();

  bool _isConnected = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;

  /// Stream of document events
  Stream<DocumentEvent> get events => _eventController.stream;

  /// Whether the WebSocket is currently connected
  bool get isConnected => _isConnected;

  /// Connect to the WebSocket server
  void connect() {
    if (_isConnected) {
      print('WebSocket already connected');
      return;
    }

    try {
      print('Connecting to WebSocket: ${ApiConfig.wsUrl}');

      _channel = WebSocketChannel.connect(
        Uri.parse(ApiConfig.wsUrl),
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      // Listen to WebSocket messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      print('WebSocket connected successfully');
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    print('Disconnecting from WebSocket');

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
  }

  /// Handle incoming WebSocket messages
  void _onMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final event = DocumentEvent.fromJson(json);
      _eventController.add(event);
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _onError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
  }

  /// Handle WebSocket connection closed
  void _onDone() {
    print('WebSocket connection closed');
    _isConnected = false;
    _scheduleReconnect();
  }

  /// Schedule a reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= ApiConfig.maxReconnectAttempts) {
      print('Max reconnect attempts reached. Stopping reconnection.');
      return;
    }

    _reconnectAttempts++;

    final delay = ApiConfig.wsReconnectDelay * _reconnectAttempts;
    print('Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer = Timer(delay, () {
      print('Attempting to reconnect...');
      connect();
    });
  }

  /// Manually trigger reconnection
  void reconnect() {
    disconnect();
    _reconnectAttempts = 0;
    connect();
  }

  /// Send a message to the WebSocket server
  void sendMessage(String message) {
    if (!_isConnected || _channel == null) {
      print('Cannot send message: WebSocket not connected');
      return;
    }

    _channel!.sink.add(message);
  }

  /// Dispose the service and clean up resources
  void dispose() {
    disconnect();
    _eventController.close();
  }
}
