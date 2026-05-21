enum MessageType { text, photo, videoCircle, file }

class PlantMessage {
  const PlantMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.sentAt,
    this.fileName,
  });

  final String id;
  final String chatId;
  final String senderId;
  final MessageType type;
  final String content;
  final String? fileName;
  final DateTime sentAt;

  bool isMine(String currentUserId) => senderId == currentUserId;

  String get preview {
    return switch (type) {
      MessageType.text => content,
      MessageType.photo => '📷 Фото',
      MessageType.videoCircle => '⭕ Видеокружок',
      MessageType.file => '📎 ${fileName ?? 'Файл'}',
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'type': type.name,
        'content': content,
        'fileName': fileName,
        'sentAt': sentAt.toIso8601String(),
      };

  factory PlantMessage.fromJson(Map<String, dynamic> json) => PlantMessage(
        id: json['id'] as String,
        chatId: json['chatId'] as String,
        senderId: json['senderId'] as String,
        type: MessageType.values.byName(json['type'] as String),
        content: json['content'] as String,
        fileName: json['fileName'] as String?,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );
}
