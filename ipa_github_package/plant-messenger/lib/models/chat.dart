class ChatPreview {
  const ChatPreview({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.online,
    required this.avatarColor,
  });

  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;
  final int avatarColor;
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.time,
    required this.isMine,
  });

  final String text;
  final String time;
  final bool isMine;
}

const demoChats = [
  ChatPreview(
    id: '1',
    name: 'Анна',
    lastMessage: 'Привет! Как дела?',
    time: '14:32',
    unread: 2,
    online: true,
    avatarColor: 0xFF2D6B32,
  ),
  ChatPreview(
    id: '2',
    name: 'Команда PLANT',
    lastMessage: 'Встреча в 18:00',
    time: '12:05',
    unread: 0,
    online: false,
    avatarColor: 0xFF1B521B,
  ),
  ChatPreview(
    id: '3',
    name: 'Максим',
    lastMessage: 'Отправил фото',
    time: 'Вчера',
    unread: 1,
    online: true,
    avatarColor: 0xFF3D8B48,
  ),
  ChatPreview(
    id: '4',
    name: 'Елена',
    lastMessage: 'Спасибо!',
    time: 'Пн',
    unread: 0,
    online: false,
    avatarColor: 0xFF4A9B54,
  ),
];

const demoMessages = [
  ChatMessage(text: 'Привет! 👋', time: '14:20', isMine: false),
  ChatMessage(text: 'Привет! Как дела?', time: '14:21', isMine: false),
  ChatMessage(text: 'Отлично, работаю над приложением PLANT', time: '14:25', isMine: true),
  ChatMessage(
    text: 'Звучит круто! Покажешь, когда будет готово?',
    time: '14:28',
    isMine: false,
  ),
  ChatMessage(text: 'Конечно, скоро отправлю скриншоты', time: '14:30', isMine: true),
  ChatMessage(text: 'Жду с нетерпением 🌿', time: '14:32', isMine: false),
];
