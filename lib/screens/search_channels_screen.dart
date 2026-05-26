import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/plant_channel.dart';
import '../services/plant_data_service.dart';
import '../theme/plant_colors.dart';
import '../widgets/plant_search_field.dart';
import 'channel_screen.dart';

class SearchChannelsScreen extends StatefulWidget {
  const SearchChannelsScreen({super.key});

  @override
  State<SearchChannelsScreen> createState() => _SearchChannelsScreenState();
}

class _SearchChannelsScreenState extends State<SearchChannelsScreen> {
  final _queryController = TextEditingController();
  List<PlantChannel> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await PlantDataService.instance.searchChannels(query);
      setState(() => _results = results);
    } catch (_) {
      setState(() => _results = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = PlantDataService.instance;
    final currentId = data.currentUserId;

    return Scaffold(
      backgroundColor: PlantColors.chatBg,
      appBar: AppBar(
        backgroundColor: PlantColors.header,
        foregroundColor: Colors.white,
        title: Text(
          'Поиск каналов',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: PlantSearchField(
              hint: 'Введите название канала...',
              onChanged: _search,
            ),
          ),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: PlantColors.header),
              ),
            )
          else if (_results.isEmpty && _queryController.text.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Каналы не найдены',
                  style: GoogleFonts.nunito(
                    color: PlantColors.forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Color(0x331A4A1A),
                ),
                itemBuilder: (context, index) {
                  final channel = _results[index];
                  final isSubscribed = currentId != null &&
                      channel.isSubscribed(currentId);
                  final isOwner = currentId != null &&
                      channel.isOwner(currentId);

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ChannelScreen(channelId: channel.id),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: PlantColors.header.withValues(alpha: 0.2),
                      child: Icon(Icons.campaign, color: PlantColors.header),
                    ),
                    title: Text(
                      channel.name,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: PlantColors.darkGreen,
                      ),
                    ),
                    subtitle: channel.description.isNotEmpty
                        ? Text(
                            channel.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: PlantColors.forest.withValues(alpha: 0.8),
                            ),
                          )
                        : null,
                    trailing: isOwner
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: PlantColors.header.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'владелец',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: PlantColors.header,
                              ),
                            ),
                          )
                        : isSubscribed
                            ? const Icon(Icons.check_circle, color: PlantColors.header)
                            : TextButton(
                                onPressed: () async {
                                  await data.subscribeToChannel(channel.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Подписан на канал',
                                        style: GoogleFonts.nunito(),
                                      ),
                                      backgroundColor: PlantColors.header,
                                    ),
                                  );
                                  _search(_queryController.text);
                                },
                                child: Text(
                                  'Подписаться',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w800,
                                    color: PlantColors.header,
                                  ),
                                ),
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