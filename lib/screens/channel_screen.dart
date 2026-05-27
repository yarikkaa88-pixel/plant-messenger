import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/plant_channel.dart';
import '../models/plant_message.dart';
import '../services/plant_data_service.dart';
import '../theme/plant_colors.dart';
import '../widgets/message_bubble.dart' hide _MessageContent, _PhotoContent, _FileContent;
import '../widgets/plant_search_field.dart';

class ChannelScreen extends StatefulWidget {
  const ChannelScreen({super.key, required this.channelId});

  final String channelId;

  @override
  State<ChannelScreen> createState() => _ChannelScreenState();
}

class _ChannelScreenState extends State<ChannelScreen> {
  final _postController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    PlantDataService.instance.addListener(_refresh);
    _load();
  }

  Future<void> _load() async {
    await PlantDataService.instance.refreshChannel(widget.channelId);
  }

  @override
  void dispose() {
    PlantDataService.instance.removeListener(_refresh);
    _postController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  PlantDataService get _data => PlantDataService.instance;

  PlantChannel? get _channel => _data.getChannelById(widget.channelId);

  bool get _isOwner {
    final channel = _channel;
    if (channel == null) return false;
    return channel.isOwner(_data.currentUserId!);
  }

  bool get _isSubscribed {
    final channel = _channel;
    if (channel == null) return false;
    return channel.isSubscribed(_data.currentUserId!);
  }

  Future<void> _postText() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;
    _postController.clear();
    await _data.addChannelPost(
      channelId: widget.channelId,
      type: MessageType.text,
      content: text,
    );
  }

  Future<void> _postPhoto() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await _data.addChannelPost(
      channelId: widget.channelId,
      type: MessageType.photo,
      content: file.path,
      file: File(file.path),
    );
  }

  Future<void> _postVideoCircle() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await _data.addChannelPost(
      channelId: widget.channelId,
      type: MessageType.videoCircle,
      content: file.path,
      file: File(file.path),
    );
  }

  Future<void> _subscribe() async {
    await _data.subscribeToChannel(widget.channelId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Вы подписались на канал', style: GoogleFonts.nunito()),
        backgroundColor: PlantColors.header,
      ),
    );
  }

  Future<void> _showComments(ChannelPost post) async {
    final commentController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PlantColors.chatBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final channel = _data.getChannelById(widget.channelId);
            final currentPost = channel?.posts.firstWhere((p) => p.id == post.id);
            if (currentPost == null) return const SizedBox.shrink();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.6,
                minChildSize: 0.4,
                maxChildSize: 0.9,
                builder: (_, scrollController) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: PlantColors.forest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        'Комментарии',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: PlantColors.darkGreen,
                        ),
                      ),
                      Expanded(
                        child: currentPost.comments.isEmpty
                            ? Center(
                                child: Text(
                                  'Пока нет комментариев',
                                  style: GoogleFonts.nunito(
                                    color: PlantColors.forest.withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: currentPost.comments.length,
                                itemBuilder: (_, i) {
                                  final c = currentPost.comments[i];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: PlantColors.listTile,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.userName,
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.w800,
                                            color: PlantColors.header,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.text,
                                          style: GoogleFonts.nunito(
                                            color: PlantColors.darkGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (_isSubscribed)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: commentController,
                                  decoration: InputDecoration(
                                    hintText: 'Комментарий...',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(22),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  if (commentController.text.trim().isEmpty) return;
                                  await _data.addComment(
                                    channelId: widget.channelId,
                                    postId: post.id,
                                    text: commentController.text,
                                  );
                                  commentController.clear();
                                  setModalState(() {});
                                },
                                icon: const Icon(Icons.send, color: PlantColors.header),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
    commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = _channel;
    if (channel == null) {
      return const Scaffold(body: Center(child: Text('Канал не найден')));
    }

    return Scaffold(
      backgroundColor: PlantColors.chatBg,
      appBar: AppBar(
        backgroundColor: PlantColors.header,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              channel.name,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              '${channel.subscriberIds.length} подписчиков',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
        actions: [
          if (!_isSubscribed)
            TextButton(
              onPressed: _subscribe,
              child: Text(
                'Подписаться',
                style: GoogleFonts.nunito(
                  color: PlantColors.lime,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (channel.description.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PlantColors.listTile,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                channel.description,
                style: GoogleFonts.nunito(color: PlantColors.darkGreen),
              ),
            ),
          Expanded(
            child: channel.posts.isEmpty
                ? Center(
                    child: Text(
                      _isOwner ? 'Опубликуйте первый пост' : 'Пока нет постов',
                      style: GoogleFonts.nunito(
                        color: PlantColors.forest.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: channel.posts.length,
                    itemBuilder: (context, index) {
                      final post = channel.posts[index];
                      return _ChannelPostCard(
                        post: post,
                        currentUserId: _data.currentUserId!,
                        onReact: (emoji) => _data.toggleReaction(
                          channelId: widget.channelId,
                          postId: post.id,
                          emoji: emoji,
                        ),
                        onComments: () => _showComments(post),
                      );
                    },
                  ),
          ),
          if (_isOwner) _OwnerPostBar(
            controller: _postController,
            onPostText: _postText,
            onPostPhoto: _postPhoto,
            onPostVideo: _postVideoCircle,
          ),
        ],
      ),
    );
  }
}

class _ChannelPostCard extends StatelessWidget {
  const _ChannelPostCard({
    required this.post,
    required this.currentUserId,
    required this.onReact,
    required this.onComments,
  });

  final ChannelPost post;
  final String currentUserId;
  final ValueChanged<String> onReact;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PlantColors.listTile),
        boxShadow: [
          BoxShadow(
            color: PlantColors.darkGreen.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostContent(post: post),
          const SizedBox(height: 10),
          ReactionBar(
            reactions: post.reactions,
            currentUserId: currentUserId,
            onReact: onReact,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onComments,
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18, color: PlantColors.forest),
                const SizedBox(width: 6),
                Text(
                  '${post.comments.length} комментариев',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: PlantColors.forest,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              PlantDataService.formatTime(post.sentAt),
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: PlantColors.forest.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostContent extends StatelessWidget {
  const _PostContent({required this.post});

  final ChannelPost post;

  @override
  Widget build(BuildContext context) {
    return switch (post.type) {
      MessageType.text => Text(
          post.content,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: PlantColors.darkGreen,
            height: 1.35,
          ),
        ),
      MessageType.photo => _ChannelPhoto(path: post.content),
      MessageType.videoCircle => VideoCircleBubble(path: post.content),
      MessageType.file => _ChannelFile(fileName: post.fileName ?? 'Файл', fileUrl: post.content),
    };
  }
}

class _ChannelPhoto extends StatelessWidget {
  const _ChannelPhoto({required this.path});

  final String path;

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');
  bool get _isDataUrl => path.startsWith('data:');

  void _openImage(BuildContext context) {
    final provider = _makeProvider();
    if (provider == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image(image: provider, fit: BoxFit.contain),
        ),
      ),
    );
  }

  ImageProvider? _makeProvider() {
    if (_isDataUrl) {
      final comma = path.indexOf(',');
      if (comma == -1) return null;
      final bytes = base64Decode(path.substring(comma + 1));
      return MemoryImage(bytes);
    }
    if (_isNetwork) return NetworkImage(path);
    final file = File(path);
    if (file.existsSync()) return FileImage(file);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _makeProvider();
    if (provider == null) {
      return const Text('📷 Фото');
    }
    return GestureDetector(
      onTap: () => _openImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(image: provider, width: double.infinity, fit: BoxFit.cover),
      ),
    );
  }
}

class _ChannelFile extends StatelessWidget {
  const _ChannelFile({required this.fileName, required this.fileUrl});

  final String fileName;
  final String fileUrl;

  Future<void> _openFile() async {
    final uri = Uri.parse(fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: PlantColors.listTile,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, color: PlantColors.forest),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: PlantColors.darkGreen,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new, size: 16, color: PlantColors.forest),
          ],
        ),
      ),
    );
  }
}

class _OwnerPostBar extends StatelessWidget {
  const _OwnerPostBar({
    required this.controller,
    required this.onPostText,
    required this.onPostPhoto,
    required this.onPostVideo,
  });

  final TextEditingController controller;
  final VoidCallback onPostText;
  final VoidCallback onPostPhoto;
  final VoidCallback onPostVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: PlantColors.listTile,
        border: Border(top: BorderSide(color: PlantColors.forest.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Публикация (владелец)',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: PlantColors.header,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.add_circle_outline, color: PlantColors.forest),
                color: PlantColors.limeLight,
                onSelected: (v) {
                  switch (v) {
                    case 'photo':
                      onPostPhoto();
                    case 'video':
                      onPostVideo();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'photo', child: Text('📷 Фото')),
                  const PopupMenuItem(value: 'video', child: Text('⭕ Видеокружок')),
                ],
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Новый пост...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => onPostText(),
                ),
              ),
              IconButton(
                onPressed: onPostText,
                icon: const Icon(Icons.send, color: PlantColors.header),
              ),
            ],
          ),
        ],
      ),
    );
  }
}