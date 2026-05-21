import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';

class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  io.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  void connect(String token) {
    if (_socket != null) return;

    final socket = io.io(
      ApiConfig.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .setAuth({'token': token})
          .build(),
    );

    socket.on('message:new', (data) {
      if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
    });

    socket.connect();
    _socket = socket;
  }

  void joinChat(String chatId) => _socket?.emit('chat:join', chatId);

  void leaveChat(String chatId) => _socket?.emit('chat:leave', chatId);

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
