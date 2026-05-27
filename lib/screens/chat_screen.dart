import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plant_message.dart';
import '../services/plant_data_service.dart';
import '../services/realtime_service.dart';
import '../theme/plant_colors.dart';
import '../widgets/default_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/plant_search_field.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _loading = true;
  StreamSubscription<Map<String, dynamic>>? _messageSub;

  @override
  void initState() {
    super.initState();
    PlantDataService.instance.addListener(_refresh);
    RealtimeService.instance.joinChat(widget.chatId);
    _messageSub = RealtimeService.instance.messages.listen((payload) {
      if (!mounted) return;
      final chatId = payload['chatId'];
      if (chatId == widget.chatId) {
        PlantDataService.instance.loadChatMessages(widget.chatId);
      }
    });
    _load();
  }

  Future<void> _load() async {
    try {
      await PlantDataService.instance.loadChatMessages(widget.chatId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    RealtimeService.instance.leaveChat(widget.chatId);
    PlantDataService.instance.removeListener(_refresh);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  PlantDataService get _data => PlantDataService.instance;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _data.sendMessage(
      chatId: widget.chatId,
      type: MessageType.text,
      content: text,
    );
    _scrollToBottom();
  }

  Future<void> _sendPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _data.sendMessage(
      chatId: widget.chatId,
      type: MessageType.photo,
      content: picked.path,
      file: File(picked.path),
    );
    _scrollToBottom();
  }

  Future<void> _sendVideoCircle() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    await _data.sendMessage(
      chatId: widget.chatId,
      type: MessageType.videoCircle,
      content: picked.path,
      file: File(picked.path),
    );
    _scrollToBottom();
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.path == null) return;
    await _data.sendMessage(
      chatId: widget.chatId,
      type: MessageType.file,
      content: picked.path!,
      fileName: picked.name,
      file: File(picked.path!),
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: PlantColors.chatBg,
        body: const Center(
          child: CircularProgressIndicator(color: PlantColors.header),
        ),
      );
    }

    final chat = _data.getChatById(widget.chatId);
    if (chat == null) {
      return const Scaffold(body: Center(child: Text('Чат не найден')));
    }

    final otherId = chat.otherUserId(_data.currentUserId!);
    final user = otherId == null ? null : _data.getUserById(otherId);

    return Scaffold(
      backgroundColor: PlantColors.chatBg,
      appBar: AppBar(
        backgroundColor: PlantColors.header,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: user?.avatarProvider() ?? const AssetImage('default_avatar.png'),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.nickname ?? 'Чат',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    user?.phone ?? '',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: Text(
                      'Напишите первое сообщение',
                      style: GoogleFonts.nunito(
                        color: PlantColors.forest.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chat.messages[index];
                      return MessageBubble(
                        message: msg,
                        isMine: msg.isMine(_data.currentUserId!),
                      );
                    },
                  ),
          ),
          ChatInputBar(
            controller: _controller,
            onSend: _sendText,
            onAttachFile: _sendFile,
            onAttachPhoto: _sendPhoto,
            onAttachVideoCircle: _sendVideoCircle,
          ),
        ],
      ),
    );
  }
}
