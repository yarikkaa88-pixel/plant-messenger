import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_user.dart';
import '../services/plant_data_service.dart';
import '../theme/plant_colors.dart';
import '../widgets/default_avatar.dart';
import '../widgets/plant_search_field.dart';
import 'chat_screen.dart';

class SearchPeopleScreen extends StatefulWidget {
  const SearchPeopleScreen({super.key});

  @override
  State<SearchPeopleScreen> createState() => _SearchPeopleScreenState();
}

class _SearchPeopleScreenState extends State<SearchPeopleScreen> {
  final _controller = TextEditingController();
  List<PlantUser> _results = [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await PlantDataService.instance.searchUsers(query);
      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searching = false;
          _error = 'Ошибка поиска. Проверьте сервер.';
        });
      }
    }
  }

  Future<void> _startChat(PlantUser user) async {
    try {
      final chat = await PlantDataService.instance.getOrCreateChat(user.id);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(chatId: chat.id),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось создать чат', style: GoogleFonts.nunito()),
            backgroundColor: PlantColors.header,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlantColors.chatBg,
      appBar: AppBar(
        backgroundColor: PlantColors.header,
        foregroundColor: Colors.white,
        title: Text(
          'Поиск людей',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: PlantSearchField(
              controller: _controller,
              hint: 'Никнейм или номер телефона',
              onChanged: _search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Демо: anna, maxim, elena (пароли: anna123, maxim123...)',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: PlantColors.forest.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_searching) const LinearProgressIndicator(color: PlantColors.header),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _controller.text.isEmpty
                          ? 'Введите ник или номер'
                          : 'Никого не найдено',
                      style: GoogleFonts.nunito(
                        color: PlantColors.forest.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(
                      indent: 72,
                      color: Color(0x331A4A1A),
                    ),
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      return ListTile(
                        leading: const DefaultAvatar(radius: 20),
                        title: Text(
                          user.nickname,
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: PlantColors.darkGreen,
                          ),
                        ),
                        subtitle: Text(
                          user.phone,
                          style: GoogleFonts.nunito(
                            color: PlantColors.forest.withValues(alpha: 0.7),
                          ),
                        ),
                        trailing: FilledButton(
                          onPressed: () => _startChat(user),
                          style: FilledButton.styleFrom(
                            backgroundColor: PlantColors.header,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Чат'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
