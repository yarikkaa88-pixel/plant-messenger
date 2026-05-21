import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/plant_colors.dart';

class PlantSearchField extends StatelessWidget {
  const PlantSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(color: PlantColors.forest.withValues(alpha: 0.6)),
        prefixIcon: const Icon(Icons.search, color: PlantColors.forest),
        filled: true,
        fillColor: PlantColors.listTile,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }
}

class ReactionBar extends StatelessWidget {
  const ReactionBar({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReact,
  });

  final Map<String, List<String>> reactions;
  final String currentUserId;
  final ValueChanged<String> onReact;

  static const emojis = ['👍', '❤️', '🔥', '🌿', '😂', '👏'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...emojis.map((emoji) {
          final count = reactions[emoji]?.length ?? 0;
          final mine = reactions[emoji]?.contains(currentUserId) ?? false;
          return GestureDetector(
            onTap: () => onReact(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: mine ? PlantColors.header : PlantColors.listTile,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: mine ? PlantColors.header : PlantColors.forest.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                count > 0 ? '$emoji $count' : emoji,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: mine ? Colors.white : PlantColors.darkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttachFile,
    required this.onAttachPhoto,
    required this.onAttachVideoCircle,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttachFile;
  final VoidCallback onAttachPhoto;
  final VoidCallback onAttachVideoCircle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        4,
        8,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: PlantColors.listTile,
        boxShadow: [
          BoxShadow(
            color: PlantColors.darkGreen.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline, color: PlantColors.forest),
            color: PlantColors.limeLight,
            onSelected: (value) {
              switch (value) {
                case 'photo':
                  onAttachPhoto();
                case 'video':
                  onAttachVideoCircle();
                case 'file':
                  onAttachFile();
              }
            },
            itemBuilder: (_) => [
              _menuItem('photo', Icons.photo, 'Фото'),
              _menuItem('video', Icons.videocam, 'Видеокружок'),
              _menuItem('file', Icons.attach_file, 'Файл'),
            ],
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Сообщение',
                hintStyle: GoogleFonts.nunito(color: PlantColors.forest.withValues(alpha: 0.5)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: PlantColors.header,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: PlantColors.header, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w700,
              color: PlantColors.darkGreen,
            ),
          ),
        ],
      ),
    );
  }
}
