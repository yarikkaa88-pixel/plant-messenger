import 'plant_message.dart';

class ChannelComment {
  const ChannelComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
      };

  factory ChannelComment.fromJson(Map<String, dynamic> json) => ChannelComment(
        id: json['id'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        text: json['text'] as String,
        sentAt: DateTime.parse(json['sentAt'] as String),
      );
}

class ChannelPost {
  const ChannelPost({
    required this.id,
    required this.channelId,
    required this.type,
    required this.content,
    required this.sentAt,
    this.fileName,
    this.reactions = const {},
    this.comments = const [],
  });

  final String id;
  final String channelId;
  final MessageType type;
  final String content;
  final String? fileName;
  final DateTime sentAt;
  final Map<String, List<String>> reactions;
  final List<ChannelComment> comments;

  int get totalReactions =>
      reactions.values.fold(0, (sum, list) => sum + list.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'channelId': channelId,
        'type': type.name,
        'content': content,
        'fileName': fileName,
        'sentAt': sentAt.toIso8601String(),
        'reactions': reactions,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  factory ChannelPost.fromJson(Map<String, dynamic> json) {
    final rawReactions = json['reactions'] as Map<String, dynamic>? ?? {};
    return ChannelPost(
      id: json['id'] as String,
      channelId: json['channelId'] as String,
      type: MessageType.values.byName(json['type'] as String),
      content: json['content'] as String,
      fileName: json['fileName'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String),
      reactions: rawReactions.map(
        (key, value) => MapEntry(key, (value as List).cast<String>()),
      ),
      comments: (json['comments'] as List? ?? [])
          .map((e) => ChannelComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  ChannelPost copyWith({
    Map<String, List<String>>? reactions,
    List<ChannelComment>? comments,
  }) =>
      ChannelPost(
        id: id,
        channelId: channelId,
        type: type,
        content: content,
        fileName: fileName,
        sentAt: sentAt,
        reactions: reactions ?? this.reactions,
        comments: comments ?? this.comments,
      );
}

class PlantChannel {
  const PlantChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    this.subscriberIds = const [],
    this.posts = const [],
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> subscriberIds;
  final List<ChannelPost> posts;

  bool isOwner(String userId) => ownerId == userId;
  bool isSubscribed(String userId) => subscriberIds.contains(userId);

  ChannelPost? get lastPost => posts.isEmpty ? null : posts.last;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'subscriberIds': subscriberIds,
        'posts': posts.map((p) => p.toJson()).toList(),
      };

  factory PlantChannel.fromJson(Map<String, dynamic> json) => PlantChannel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        ownerId: json['ownerId'] as String,
        subscriberIds: (json['subscriberIds'] as List? ?? []).cast<String>(),
        posts: (json['posts'] as List? ?? [])
            .map((e) => ChannelPost.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  PlantChannel copyWith({
    List<String>? subscriberIds,
    List<ChannelPost>? posts,
  }) =>
      PlantChannel(
        id: id,
        name: name,
        description: description,
        ownerId: ownerId,
        subscriberIds: subscriberIds ?? this.subscriberIds,
        posts: posts ?? this.posts,
      );
}
