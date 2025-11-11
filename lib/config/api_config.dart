/// API Configuration for DocExtract Backend
class ApiConfig {
  /// Base URL for the API
  /// Can be overridden using --dart-define=API_BASE_URL=https://your-api.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// WebSocket URL for real-time updates
  /// Can be overridden using --dart-define=WS_URL=wss://your-api.com/ws/documents
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://localhost:8000/ws/documents',
  );

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
