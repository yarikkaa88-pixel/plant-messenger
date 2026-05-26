import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plant_channel.dart';
import '../models/plant_chat.dart';
import '../models/plant_message.dart';
import '../models/plant_user.dart';
import '../services/plant_data_service.dart';
import '../theme/plant_colors.dart';
import '../widgets/default_avatar.dart';
import '../widgets/plant_search_field.dart';
import 'channel_screen.dart';
import 'chat_screen.dart';
import 'create_channel_screen.dart';
import 'search_channels_screen.dart';
import 'search_people_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 2;
  int _chatSubTab = 0;
  String _chatFilter = '';

  @override
  void initState() {
    super.initState();
    PlantDataService.instance.addListener(_onDataChanged);
    PlantDataService.instance.refreshAll();
  }

  @override
  void dispose() {
    PlantDataService.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final data = PlantDataService.instance;
    final chats = data.myChats.where((chat) {
      if (_chatFilter.isEmpty) return true;
      final otherId = chat.otherUserId(data.currentUserId!);
      final user = otherId == null ? null : data.getUserById(otherId);
      if (user == null) return false;
      final q = _chatFilter.toLowerCase();
      return user.nickname.toLowerCase().contains(q) ||
          user.phone.contains(q);
    }).toList();

    final channels = data.myChannels;
    final contacts = _extractContacts(chats, data);
    final title = switch (_tab) {
      0 => 'Контакты',
      1 => 'Звонки',
      2 => 'Чаты',
      _ => 'Профиль',
    };

    return Scaffold(
      backgroundColor: PlantColors.chatBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: PlantColors.header,
                    ),
                  ),
                  const Spacer(),
                  if (_tab == 0 || _tab == 2)
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const SearchPeopleScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1),
                      color: PlantColors.header,
                      tooltip: 'Найти человека',
                    ),
                  if (_tab == 2 && _chatSubTab == 1)
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const CreateChannelScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      color: PlantColors.header,
                      tooltip: 'Создать канал',
                    ),
                ],
              ),
            ),
            if (_tab == 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<int>(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      if (states.contains(MaterialState.selected)) {
                        return PlantColors.header.withValues(alpha: 0.15);
                      }
                      return PlantColors.listTile;
                    }),
                    foregroundColor: MaterialStateProperty.all(PlantColors.darkGreen),
                  ),
                  segments: const [
                    ButtonSegment(value: 0, icon: Icon(Icons.chat_bubble_outline), label: Text('Чаты')),
                    ButtonSegment(value: 1, icon: Icon(Icons.campaign_outlined), label: Text('Каналы')),
                  ],
                  selected: {_chatSubTab},
                  onSelectionChanged: (value) => setState(() => _chatSubTab = value.first),
                ),
              ),
            if (_tab == 2 && _chatSubTab == 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PlantSearchField(
                  hint: 'Поиск по нику или номеру',
                  onChanged: (v) => setState(() => _chatFilter = v),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: switch (_tab) {
                0 => _ContactsList(contacts: contacts),
                1 => _CallsList(chats: chats),
                2 => _chatSubTab == 0
                    ? _ChatsList(chats: chats)
                    : _ChannelsList(channels: channels),
                _ => _ProfileTab(user: data.currentUser),
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: PlantColors.listTile,
        indicatorColor: PlantColors.header.withValues(alpha: 0.2),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts, color: PlantColors.header),
            label: 'Контакты',
          ),
          NavigationDestination(
            icon: Icon(Icons.call_outlined),
            selectedIcon: Icon(Icons.call, color: PlantColors.header),
            label: 'Звонки',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: PlantColors.header),
            label: 'Чаты',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: PlantColors.header),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }

  List<_ContactItem> _extractContacts(List<PlantChat> chats, PlantDataService data) {
    final ids = <String>{};
    final contacts = <_ContactItem>[];
    for (final chat in chats) {
      final otherId = chat.otherUserId(data.currentUserId!);
      if (otherId == null || ids.contains(otherId)) continue;
      final user = data.getUserById(otherId);
      if (user == null) continue;
      ids.add(otherId);
      contacts.add(_ContactItem(user: user, chatId: chat.id));
    }
    return contacts;
  }
}

class _ContactItem {
  const _ContactItem({required this.user, required this.chatId});

  final PlantUser user;
  final String chatId;
}

class _ContactsList extends StatelessWidget {
  const _ContactsList({required this.contacts});

  final List<_ContactItem> contacts;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Center(
        child: Text(
          'Контакты появятся после переписки',
          style: GoogleFonts.nunito(
            color: PlantColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, color: Color(0x331A4A1A)),
      itemBuilder: (context, index) {
        final item = contacts[index];
        final user = item.user;
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => ChatScreen(chatId: item.chatId)),
            );
          },
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: const AssetImage('default_avatar.png'),
            backgroundColor: Colors.transparent,
          ),
          title: Text(
            user.nickname,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: PlantColors.darkGreen),
          ),
          subtitle: Text(
            user.phone,
            style: GoogleFonts.nunito(color: PlantColors.forest.withValues(alpha: 0.8)),
          ),
          trailing: Icon(Icons.chevron_right, color: PlantColors.forest.withValues(alpha: 0.7)),
        );
      },
    );
  }
}

class _CallsList extends StatelessWidget {
  const _CallsList({required this.chats});

  final List<PlantChat> chats;

  @override
  Widget build(BuildContext context) {
    final data = PlantDataService.instance;
    if (chats.isEmpty) {
      return Center(
        child: Text(
          'История звонков пока пустая',
          style: GoogleFonts.nunito(
            color: PlantColors.forest,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, color: Color(0x331A4A1A)),
      itemBuilder: (context, index) {
        final chat = chats[index];
        final otherId = chat.otherUserId(data.currentUserId!);
        final user = otherId == null ? null : data.getUserById(otherId);
        if (user == null) return const SizedBox.shrink();
        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: const AssetImage('default_avatar.png'),
            backgroundColor: Colors.transparent,
          ),
          title: Text(
            user.nickname,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800, color: PlantColors.darkGreen),
          ),
          subtitle: Text(
            'Недавний звонок',
            style: GoogleFonts.nunito(color: PlantColors.forest.withValues(alpha: 0.8)),
          ),
          trailing: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: PlantColors.listTile,
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.call, color: PlantColors.header),
              tooltip: 'Позвонить',
            ),
          ),
        );
      },
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.user});

  final PlantUser? user;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late bool _hidePhone;

  @override
  void initState() {
    super.initState();
    _hidePhone = widget.user?.hidePhone ?? false;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await PlantDataService.instance.updateProfile(
      avatarFile: File(file.path),
    );
    setState(() {});
  }

  Future<void> _toggleHidePhone() async {
    await PlantDataService.instance.updateProfile(
      hidePhone: !_hidePhone,
    );
    setState(() => _hidePhone = !_hidePhone);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user ?? PlantDataService.instance.currentUser;
    final data = PlantDataService.instance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: PlantColors.listTile,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PlantColors.header.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: user?.avatarPath != null
                            ? NetworkImage(user!.avatarPath!)
                            : const AssetImage('default_avatar.png') as ImageProvider,
                        backgroundColor: Colors.transparent,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: PlantColors.header,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.nickname ?? 'Пользователь',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: PlantColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _hidePhone ? user!.displayPhone : (user?.phone ?? ''),
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: PlantColors.forest,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: PlantColors.listTile,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Скрыть номер телефона',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: PlantColors.darkGreen,
                    ),
                  ),
                  subtitle: Text(
                    _hidePhone ? 'Номер скрыт' : 'Номер виден всем',
                    style: GoogleFonts.nunito(color: PlantColors.forest),
                  ),
                  value: _hidePhone,
                  activeColor: PlantColors.header,
                  onChanged: (_) => _toggleHidePhone(),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(
                    'Выйти',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  onTap: () async {
                    await data.clearSession();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatsList extends StatelessWidget {
  const _ChatsList({required this.chats});

  final List<PlantChat> chats;

  @override
  Widget build(BuildContext context) {
    final data = PlantDataService.instance;

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_outlined, size: 64, color: PlantColors.forest.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Нет чатов',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PlantColors.forest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Найдите человека по нику\nили номеру телефона',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: PlantColors.forest.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SearchPeopleScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: PlantColors.header,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.search),
              label: const Text('Найти человека'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 76,
        color: Color(0x331A4A1A),
      ),
      itemBuilder: (context, index) {
        final chat = chats[index];
        final otherId = chat.otherUserId(data.currentUserId!);
        final user = otherId == null ? null : data.getUserById(otherId);
        if (user == null) return const SizedBox.shrink();

        final last = chat.lastMessage;
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(chatId: chat.id),
              ),
            );
          },
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: const AssetImage('default_avatar.png'),
            backgroundColor: Colors.transparent,
          ),
          title: Text(
            user.nickname,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: PlantColors.darkGreen,
            ),
          ),
          subtitle: Text(
            last?.preview ?? 'Начните переписку',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              color: PlantColors.forest.withValues(alpha: 0.75),
            ),
          ),
          trailing: last == null
              ? null
              : Text(
                  PlantDataService.formatTime(last.sentAt),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: PlantColors.forest.withValues(alpha: 0.7),
                  ),
                ),
        );
      },
    );
  }
}

class _ChannelsList extends StatelessWidget {
  const _ChannelsList({required this.channels});

  final List<PlantChannel> channels;

  @override
  Widget build(BuildContext context) {
    final data = PlantDataService.instance;

    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: PlantColors.forest.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Нет каналов',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: PlantColors.forest,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateChannelScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: PlantColors.header,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Создать канал'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SearchChannelsScreen(),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: PlantColors.header,
                side: const BorderSide(color: PlantColors.header),
              ),
              icon: const Icon(Icons.search),
              label: const Text('Найти канал'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: channels.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76, color: Color(0x331A4A1A)),
      itemBuilder: (context, index) {
        final channel = channels[index];
        final isOwner = channel.isOwner(data.currentUserId!);
        final last = channel.lastPost;

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
            radius: 28,
            backgroundImage: const AssetImage('default_avatar.png'),
            backgroundColor: Colors.transparent,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  channel.name,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: PlantColors.darkGreen,
                  ),
                ),
              ),
              if (isOwner)
                Container(
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
                ),
            ],
          ),
          subtitle: Text(
            last?.content.isNotEmpty == true && last!.type == MessageType.text
                ? last.content
                : last?.type == MessageType.photo
                    ? '📷 Фото'
                    : last?.type == MessageType.videoCircle
                        ? '⭕ Видеокружок'
                        : channel.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(color: PlantColors.forest.withValues(alpha: 0.75)),
          ),
          trailing: Text(
            '${channel.subscriberIds.length} 👥',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: PlantColors.forest.withValues(alpha: 0.7),
            ),
          ),
        );
      },
    );
  }
}
