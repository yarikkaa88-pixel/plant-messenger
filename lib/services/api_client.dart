import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;
  String? _resolvedBaseUrl;

  String get baseUrl => ApiConfig.baseUrl;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final resolvedBaseUrl = await _resolveBaseUrl();
    final response = await _client.post(
      Uri.parse('$resolvedBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parseObject(response);
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
    final resolvedBaseUrl = await _resolveBaseUrl();
    final uri = Uri.parse('$resolvedBaseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers);
    return _parseObject(response);
  }

  Future<List<dynamic>> getJsonList(String path, {Map<String, String>? query}) async {
    final resolvedBaseUrl = await _resolveBaseUrl();
    final uri = Uri.parse('$resolvedBaseUrl$path').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers);
    return _parseList(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    File? file,
    String fileField = 'file',
  }) async {
    final resolvedBaseUrl = await _resolveBaseUrl();
    final request = http.MultipartRequest('POST', Uri.parse('$resolvedBaseUrl$path'));
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields.addAll(fields);

    if (file != null) {
      final ext = file.path.split('.').last.toLowerCase();
      MediaType? mediaType;
      if (ext == 'jpg' || ext == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (ext == 'mp4') {
        mediaType = MediaType('video', 'mp4');
      }

      request.files.add(await http.MultipartFile.fromPath(
        fileField,
        file.path,
        contentType: mediaType,
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _parseObject(response);
  }

  Map<String, dynamic> _parseObject(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final decoded = jsonDecode(body);

    if (response.statusCode >= 400) {
      final error = decoded is Map ? decoded['error'] as String? : null;
      throw ApiException(
        _errorMessage(error, response.statusCode),
        statusCode: response.statusCode,
        code: error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Неверный ответ сервера');
    }
    return decoded;
  }

  List<dynamic> _parseList(http.Response response) {
    final body = response.body.isEmpty ? '[]' : response.body;
    final decoded = jsonDecode(body);

    if (response.statusCode >= 400) {
      final error = decoded is Map ? decoded['error'] as String? : null;
      throw ApiException(
        _errorMessage(error, response.statusCode),
        statusCode: response.statusCode,
        code: error,
      );
    }

    if (decoded is! List) {
      throw ApiException('Неверный ответ сервера');
    }
    return decoded;
  }

  String _errorMessage(String? code, int status) {
    return switch (code) {
      'empty_fields' => 'Заполните все поля',
      'user_not_found' => 'Пользователь не найден',
      'wrong_password' => 'Неверный пароль',
      'nickname_taken' => 'Этот ник уже занят',
      'phone_taken' => 'Этот номер уже зарегистрирован',
      _ => status == 401
          ? 'Ошибка авторизации'
          : 'Ошибка сервера ($status)',
    };
  }

  Future<bool> checkHealth() async {
    try {
      final resolvedBaseUrl = await _resolveBaseUrl();
      final response = await _client
          .get(Uri.parse('$resolvedBaseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> _resolveBaseUrl() async {
    if (_resolvedBaseUrl != null) return _resolvedBaseUrl!;

    for (final url in ApiConfig.candidates) {
      try {
        final response = await _client
            .get(Uri.parse('$url/api/health'))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          _resolvedBaseUrl = url;
          return url;
        }
      } catch (_) {
        // continue with next candidate
      }
    }

    final discoveredLanUrl = await _discoverLanBaseUrl();
    if (discoveredLanUrl != null) {
      _resolvedBaseUrl = discoveredLanUrl;
      return discoveredLanUrl;
    }

    _resolvedBaseUrl = ApiConfig.baseUrl;
    return _resolvedBaseUrl!;
  }

  Future<String?> _discoverLanBaseUrl() async {
    final subnets = await _localSubnets();
    if (subnets.isEmpty) return null;

    for (final subnet in subnets) {
      final urls = <String>[];
      for (var i = 2; i <= 254; i++) {
        urls.add('http://$subnet.$i:3000');
      }

      final found = await _probeUrls(urls, timeout: const Duration(milliseconds: 350));
      if (found != null) return found;
    }

    return null;
  }

  Future<List<String>> _localSubnets() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      final subnets = <String>{};
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (_isPrivateIpv4(ip)) {
            final parts = ip.split('.');
            if (parts.length == 4) {
              subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
            }
          }
        }
      }
      return subnets.toList();
    } catch (_) {
      return const [];
    }
  }

  bool _isPrivateIpv4(String ip) {
    if (ip.startsWith('10.')) return true;
    if (ip.startsWith('192.168.')) return true;
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final first = int.tryParse(parts[0]) ?? -1;
    final second = int.tryParse(parts[1]) ?? -1;
    return first == 172 && second >= 16 && second <= 31;
  }

  Future<String?> _probeUrls(
    List<String> urls, {
    required Duration timeout,
  }) async {
    const concurrency = 32;
    var index = 0;

    while (index < urls.length) {
      final batch = urls.skip(index).take(concurrency).toList();
      final checks = batch.map((url) async {
        try {
          final response = await _client
              .get(Uri.parse('$url/api/health'))
              .timeout(timeout);
          if (response.statusCode == 200) return url;
        } catch (_) {}
        return null;
      }).toList();

      final results = await Future.wait(checks);
      for (final result in results) {
        if (result != null) return result;
      }
      index += concurrency;
    }

    return null;
  }
}
