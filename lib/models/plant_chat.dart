import 'plant_message.dart';

class PlantChat {
  const PlantChat({
    required this.id,
    required this.participantIds,
    this.messages = const [],
  });

  final String id;
  final List<String> participantIds;
  final List<PlantMessage> messages;

  String? otherUserId(String currentUserId) {
    for (final id in participantIds) {
      if (id != currentUserId) return id;
    }
    return null;
  }

  PlantMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantIds': participantIds,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory PlantChat.fromJson(Map<String, dynamic> json) => PlantChat(
        id: json['id'] as String,
        participantIds: (json['participantIds'] as List).cast<String>(),
        messages: (json['messages'] as List? ?? [])
            .map((e) => PlantMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  PlantChat copyWith({List<PlantMessage>? messages}) => PlantChat(
        id: id,
        participantIds: participantIds,
        messages: messages ?? this.messages,
      );
}
