import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plant_channel.dart';
import '../models/plant_chat.dart';
import '../models/plant_message.dart';
import '../models/plant_user.dart';
import 'api_client.dart';
import 'realtime_service.dart';

class PlantDataService extends ChangeNotifier {
  PlantDataService(this._prefs, this._api);

  static const _tokenKey = 'plant_token';
  static const _userKey = 'plant_user_json';

  final SharedPreferences _prefs;
  final ApiClient _api;

  static PlantDataService? _instance;

  static PlantDataService get instance {
    final service = _instance;
    if (service == null) {
      throw StateError('PlantDataService не инициализирован.');
    }
    return service;
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final api = ApiClient();
    final service = PlantDataService(prefs, api);

    final token = prefs.getString(_tokenKey);
    if (token != null) {
      api.setToken(token);
      try {
        RealtimeService.instance.connect(token);
      } catch (_) {
        // Игнорируем ошибку подключения при старте
      }
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        try {
          service._currentUser = PlantUser.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>,
          );
        } catch (_) {}
      }
    }

    _instance = service;
  }

  PlantUser? _currentUser;
  List<PlantChat> _chats = [];
  List<PlantChannel> _channels = [];
  final Map<String, PlantUser> _userCache = {};
  bool _loading = false;
  String? _lastError;

  bool get isLoading => _loading;
  String? get lastError => _lastError;
  String? get currentUserId => _currentUser?.id;
  PlantUser? get currentUser => _currentUser;
  List<PlantChat> get myChats => List.unmodifiable(_chats);
  List<PlantChannel> get myChannels => List.unmodifiable(_channels);

  ApiClient get api => _api;

  Future<void> setSession({required String token, required PlantUser user}) async {
    _api.setToken(token);
    RealtimeService.instance.connect(token);
    _currentUser = user;
    _userCache[user.id] = user;
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    await refreshAll();
  }

  Future<PlantUser> updateProfile({bool? hidePhone, File? avatarFile}) async {
    final fields = <String, String>{};
    if (hidePhone != null) fields['hidePhone'] = hidePhone.toString();
    final json = await _api.postMultipart('/api/auth/profile', fields: fields, file: avatarFile, fileField: 'avatar');
    _currentUser = PlantUser.fromJson(json);
    await _prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    notifyListeners();
    return _currentUser!;
  }

  Future<void> clearSession() async {
    _api.setToken(null);
    RealtimeService.instance.disconnect();
    _currentUser = null;
    _chats = [];
    _channels = [];
    _userCache.clear();
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
    notifyListeners();
  }

  Future<void> refreshAll() async {
    if (_currentUser == null) return;
    _loading = true;
    _lastError = null;
    notifyListeners();

    try {
      await Future.wait([refreshChats(), refreshChannels()]);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshChats() async {
    final list = await _api.getJsonList('/api/chats');
    _chats = list.map((e) => _chatFromApi(e as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  Future<void> refreshChannels() async {
    final list = await _api.getJsonList('/api/channels');
    _channels = list.map((e) => PlantChannel.fromJson(e as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  PlantChat _chatFromApi(Map<String, dynamic> json) {
    final otherUser = json['otherUser'];
    if (otherUser != null) {
      final user = PlantUser.fromJson(otherUser as Map<String, dynamic>);
      _userCache[user.id] = user;
    }

    final messages = (json['messages'] as List? ?? [])
        .map((m) => PlantMessage.fromJson(m as Map<String, dynamic>))
        .toList();

    return PlantChat(
      id: json['id'] as String,
      participantIds: (json['participantIds'] as List).cast<String>(),
      messages: messages,
    );
  }

  PlantUser? getUserById(String id) => _userCache[id];

  Future<PlantUser?> fetchUserById(String id) async {
    if (_userCache.containsKey(id)) return _userCache[id];
    try {
      final json = await _api.getJson('/api/users/$id');
      final user = PlantUser.fromJson(json);
      _userCache[id] = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<List<PlantUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final list = await _api.getJsonList('/api/users/search', query: {'q': query.trim()});
    return list.map((e) {
      final user = PlantUser.fromJson(e as Map<String, dynamic>);
      _userCache[user.id] = user;
      return user;
    }).toList();
  }

  Future<List<PlantChannel>> searchChannels(String query) async {
    if (query.trim().isEmpty) return [];
    final list = await _api.getJsonList('/api/channels/search', query: {'q': query.trim()});
    return list.map((e) => PlantChannel.fromJson(e as Map<String, dynamic>)).toList();
  }

  PlantChat? getChatById(String id) {
    for (final c in _chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  PlantChannel? getChannelById(String id) {
    for (final c in _channels) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<PlantChat> getOrCreateChat(String otherUserId) async {
    final json = await _api.postJson('/api/chats', {'otherUserId': otherUserId});
    final chat = _chatFromApi(json);
    final index = _chats.indexWhere((c) => c.id == chat.id);
    if (index >= 0) {
      _chats[index] = chat;
    } else {
      _chats.insert(0, chat);
    }
    notifyListeners();
    return chat;
  }

  Future<void> loadChatMessages(String chatId) async {
    final json = await _api.getJson('/api/chats/$chatId');
    final chat = _chatFromApi(json);
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index >= 0) {
      _chats[index] = chat;
    } else {
      _chats.add(chat);
    }
    notifyListeners();
  }

  Future<void> sendMessage({
    required String chatId,
    required MessageType type,
    required String content,
    String? fileName,
    File? file,
  }) async {
    final fields = {
      'type': type.name,
      if (type == MessageType.text) 'content': content,
      if (fileName != null) 'fileName': fileName,
    };

    final json = await _api.postMultipart(
      '/api/chats/$chatId/messages',
      fields: fields,
      file: file,
    );

    final message = PlantMessage.fromJson(json);
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index >= 0) {
      final chat = _chats[index];
      _chats[index] = chat.copyWith(messages: [...chat.messages, message]);
      notifyListeners();
    } else {
      await loadChatMessages(chatId);
    }
  }

  Future<PlantChannel> createChannel({
    required String name,
    required String description,
  }) async {
    final json = await _api.postJson('/api/channels', {
      'name': name,
      'description': description,
    });
    final channel = PlantChannel.fromJson(json);
    _channels.insert(0, channel);
    notifyListeners();
    return channel;
  }

  Future<void> subscribeToChannel(String channelId) async {
    await _api.postJson('/api/channels/$channelId/subscribe', {});
    await refreshChannel(channelId);
  }

  Future<void> refreshChannel(String channelId) async {
    final json = await _api.getJson('/api/channels/$channelId');
    final channel = PlantChannel.fromJson(json);
    final index = _channels.indexWhere((c) => c.id == channelId);
    if (index >= 0) {
      _channels[index] = channel;
    } else {
      _channels.add(channel);
    }
    notifyListeners();
  }

  Future<void> addChannelPost({
    required String channelId,
    required MessageType type,
    required String content,
    String? fileName,
    File? file,
  }) async {
    final fields = {
      'type': type.name,
      if (type == MessageType.text) 'content': content,
      if (fileName != null) 'fileName': fileName,
    };

    await _api.postMultipart(
      '/api/channels/$channelId/posts',
      fields: fields,
      file: file,
    );
    await refreshChannel(channelId);
  }

  Future<void> toggleReaction({
    required String channelId,
    required String postId,
    required String emoji,
  }) async {
    await _api.postJson(
      '/api/channels/$channelId/posts/$postId/reactions',
      {'emoji': emoji},
    );
    await refreshChannel(channelId);
  }

  Future<void> addComment({
    required String channelId,
    required String postId,
    required String text,
  }) async {
    await _api.postJson(
      '/api/channels/$channelId/posts/$postId/comments',
      {'text': text},
    );
    await refreshChannel(channelId);
  }

  static String formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (now.difference(dt).inDays == 1) return 'Вчера';
    if (now.difference(dt).inDays < 7) {
      const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}.${dt.month}';
  }
}
