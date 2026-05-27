import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/plant_message.dart';
import '../theme/plant_colors.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onDelete,
    this.onEdit,
  });

  final PlantMessage message;
  final bool isMine;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onEdit;

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.type == MessageType.text && onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Изменить'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit!.call(message.content);
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: isMine ? () => _showMenu(context) : null,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: isMine ? PlantColors.bubbleSent : PlantColors.bubbleReceived,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: PlantColors.darkGreen.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MessageContent(message: message, isMine: isMine),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatTime(message.sentAt),
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.75)
                        : PlantColors.forest.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message, required this.isMine});

  final PlantMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final textColor = isMine ? Colors.white : PlantColors.darkGreen;

    return switch (message.type) {
      MessageType.text => Text(
          message.content,
          style: GoogleFonts.nunito(
            fontSize: 15,
            color: textColor,
            height: 1.3,
          ),
        ),
      MessageType.photo => _PhotoContent(path: message.content),
      MessageType.videoCircle => VideoCircleBubble(path: message.content),
      MessageType.file => _FileContent(
          fileName: message.fileName ?? 'Файл',
          fileUrl: message.content,
          isMine: isMine,
        ),
    };
  }
}

class _PhotoContent extends StatelessWidget {
  const _PhotoContent({required this.path});

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
      return const Row(
        children: [
          Icon(Icons.image, color: Colors.white70),
          SizedBox(width: 8),
          Text('📷 Фото'),
        ],
      );
    }
    return GestureDetector(
      onTap: () => _openImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(image: provider, width: 220, fit: BoxFit.cover),
      ),
    );
  }
}

class VideoCircleBubble extends StatelessWidget {
  const VideoCircleBubble({super.key, required this.path});

  final String path;

  Future<void> _openVideo() async {
    if (path.startsWith('data:')) {
      final bytes = base64Decode(path.split(',').last);
      final tempDir = Directory.systemTemp;
      final ext = path.split(';').first.split('/').last;
      final tempFile = File('${tempDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await tempFile.writeAsBytes(bytes);
      final uri = Uri.file(tempFile.path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      final uri = Uri.parse(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openVideo,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              PlantColors.header,
              PlantColors.bubbleSent,
            ],
          ),
          border: Border.all(color: PlantColors.lime, width: 3),
          boxShadow: [
            BoxShadow(
              color: PlantColors.darkGreen.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              size: 56,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            Positioned(
              bottom: 12,
              child: Text(
                'видеокружок',
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileContent extends StatelessWidget {
  const _FileContent({
    required this.fileName,
    required this.fileUrl,
    required this.isMine,
  });

  final String fileName;
  final String fileUrl;
  final bool isMine;

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
          color: (isMine ? Colors.white : PlantColors.darkGreen)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              color: isMine ? Colors.white : PlantColors.darkGreen,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isMine ? Colors.white : PlantColors.darkGreen,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: isMine ? Colors.white70 : PlantColors.forest,
            ),
          ],
        ),
      ),
    );
  }
}