import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/plant_data_service.dart';
import '../theme/plant_colors.dart';
import 'channel_screen.dart';

class CreateChannelScreen extends StatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  State<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends State<CreateChannelScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final channel = await PlantDataService.instance.createChannel(
      name: name,
      description: _descController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChannelScreen(channelId: channel.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlantColors.chatBg,
      appBar: AppBar(
        backgroundColor: PlantColors.header,
        foregroundColor: Colors.white,
        title: Text(
          'Новый канал',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Название канала',
                labelStyle: GoogleFonts.nunito(color: PlantColors.forest),
                filled: true,
                fillColor: PlantColors.listTile,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Описание',
                labelStyle: GoogleFonts.nunito(color: PlantColors.forest),
                filled: true,
                fillColor: PlantColors.listTile,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _create,
              style: FilledButton.styleFrom(
                backgroundColor: PlantColors.header,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'СОЗДАТЬ КАНАЛ',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
