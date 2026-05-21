import 'dart:io';

class ApiConfig {
  ApiConfig._();

  /// Переопределите через --dart-define=API_URL=http://192.168.1.5:3000
  static const String _envUrl = String.fromEnvironment('API_URL');
  static const String _lanIp = String.fromEnvironment('API_LAN_IP');
  static const String _envWsUrl = String.fromEnvironment('WS_URL');

  static String get baseUrl {
    return candidates.first;
  }

  static String get wsUrl {
    if (_envWsUrl.isNotEmpty) return _envWsUrl;
    if (_envUrl.isNotEmpty) return _envUrl;
    return baseUrl;
  }

  static List<String> get candidates {
    if (_envUrl.isNotEmpty) return [_envUrl];

    final urls = <String>[
      if (Platform.isAndroid) 'http://10.0.2.2:3000',
      'http://localhost:3000',
      'http://127.0.0.1:3000',
      if (_lanIp.isNotEmpty) 'http://$_lanIp:3000',
    ];

    return urls.toSet().toList();
  }

}
