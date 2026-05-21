import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_message.dart';
import '../theme/plant_colors.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  final PlantMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
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

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(path, width: 220, fit: BoxFit.cover),
      );
    }
    final file = File(path);
    if (!file.existsSync()) {
      return const Row(
        children: [
          Icon(Icons.image, color: Colors.white70),
          SizedBox(width: 8),
          Text('📷 Фото'),
        ],
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(file, width: 220, fit: BoxFit.cover),
    );
  }
}

class VideoCircleBubble extends StatelessWidget {
  const VideoCircleBubble({super.key, required this.path, this.size = 140});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
            size: size * 0.4,
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
    );
  }
}

class _FileContent extends StatelessWidget {
  const _FileContent({required this.fileName, required this.isMine});

  final String fileName;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        ],
      ),
    );
  }
}
