import 'package:flutter/foundation.dart' show kIsWeb;

/// API Configuration for DocExtract Backend
class ApiConfig {
  /// Base URL for the API
  /// Can be overridden using --dart-define=API_BASE_URL=https://your-api.com
  /// Uses localhost for web, local network IP for mobile
  static String get baseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: '',
      ).isEmpty
          ? (kIsWeb ? 'http://localhost:8000' : 'http://192.168.0.196:8000')
          : const String.fromEnvironment('API_BASE_URL');

  /// WebSocket URL for real-time updates
  /// Can be overridden using --dart-define=WS_URL=wss://your-api.com/ws/documents
  static String get wsUrl => const String.fromEnvironment(
        'WS_URL',
        defaultValue: '',
      ).isEmpty
          ? (kIsWeb
              ? 'ws://localhost:8000/ws/documents'
              : 'ws://192.168.0.196:8000/ws/documents')
          : const String.fromEnvironment('WS_URL');

  /// API version prefix
  static const String apiVersion = '/api/v1';

  /// Full API base URL with version
  static String get apiBaseUrl => '$baseUrl$apiVersion';

  /// API Endpoints
  static const String extractEndpoint = '/extract';
  static const String documentsEndpoint = '/documents';
  static const String statsEndpoint = '/stats';

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 120);

  /// WebSocket reconnect delay
  static const Duration wsReconnectDelay = Duration(seconds: 5);

  /// Max reconnect attempts
  static const int maxReconnectAttempts = 5;
}
