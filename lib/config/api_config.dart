import 'package:flutter/foundation.dart' show kIsWeb;

/// API Configuration for DocExtract Backend
class ApiConfig {
  // Private getters for compile-time constants
  static const String _apiBaseUrlEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _wsUrlEnv = String.fromEnvironment(
    'WS_URL',
    defaultValue: '',
  );

  /// Base URL for the API
  /// Can be overridden using --dart-define=API_BASE_URL=https://your-api.com
  /// Uses localhost for web, local network IP for mobile
  static String get baseUrl {
    if (_apiBaseUrlEnv.isNotEmpty) {
      return _apiBaseUrlEnv;
    }
    // Runtime platform check
    return kIsWeb ? 'http://localhost:8000' : 'http://192.168.0.196:8000';
  }

  /// WebSocket URL for real-time updates
  /// Can be overridden using --dart-define=WS_URL=wss://your-api.com/ws/documents
  static String get wsUrl {
    if (_wsUrlEnv.isNotEmpty) {
      return _wsUrlEnv;
    }
    // Runtime platform check
    return kIsWeb
        ? 'ws://localhost:8000/ws/documents'
        : 'ws://192.168.0.196:8000/ws/documents';
  }

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
