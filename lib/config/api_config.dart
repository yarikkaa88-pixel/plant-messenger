class ApiConfig {
  ApiConfig._();

  /// URL из --dart-define=API_URL=... (если передан)
  static const String _envUrl = String.fromEnvironment('API_URL');

  /// Жёстко заданный URL сервера (если не передан через --dart-define)
  static const String _hardcodedUrl = 'https://plant-api-production-76fa.up.railway.app';

  /// Финальный URL (envUrl имеет приоритет)
  static String get _url => _envUrl.isNotEmpty ? _envUrl : _hardcodedUrl;

  /// HTTP/HTTPS URL для REST API
  static String get baseUrl => _url;

  /// WebSocket URL
  static String get wsUrl => _url
      .replaceFirst('https://', 'wss://')
      .replaceFirst('http://', 'ws://');
}
