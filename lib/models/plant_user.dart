class PlantUser {
  const PlantUser({
    required this.id,
    required this.nickname,
    required this.phone,
    this.avatarColor = 0xFF2D6B32,
    this.online = false,
  });

  final String id;
  final String nickname;
  final String phone;
  final int avatarColor;
  final bool online;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'phone': phone,
        'avatarColor': avatarColor,
        'online': online,
      };

  factory PlantUser.fromJson(Map<String, dynamic> json) => PlantUser(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        phone: json['phone'] as String,
        avatarColor: json['avatarColor'] as int? ?? 0xFF2D6B32,
        online: json['online'] as bool? ?? false,
      );

  PlantUser copyWith({bool? online}) => PlantUser(
        id: id,
        nickname: nickname,
        phone: phone,
        avatarColor: avatarColor,
        online: online ?? this.online,
      );
}
