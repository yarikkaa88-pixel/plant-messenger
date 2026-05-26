class PlantUser {
  const PlantUser({
    required this.id,
    required this.nickname,
    required this.phone,
    this.avatarColor = 0xFF2D6B32,
    this.online = false,
    this.avatarPath,
    this.hidePhone = false,
  });

  final String id;
  final String nickname;
  final String phone;
  final int avatarColor;
  final bool online;
  final String? avatarPath;
  final bool hidePhone;

  String get displayPhone => hidePhone ? phone.replaceRange(4, 7, '***') : phone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'phone': phone,
        'avatarColor': avatarColor,
        'online': online,
        'avatarPath': avatarPath,
        'hidePhone': hidePhone,
      };

  factory PlantUser.fromJson(Map<String, dynamic> json) => PlantUser(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        phone: json['phone'] as String,
        avatarColor: json['avatarColor'] as int? ?? 0xFF2D6B32,
        online: json['online'] as bool? ?? false,
        avatarPath: json['avatarPath'] as String?,
        hidePhone: json['hidePhone'] as bool? ?? false,
      );

  PlantUser copyWith({
    bool? online,
    String? avatarPath,
    bool? hidePhone,
  }) =>
      PlantUser(
        id: id,
        nickname: nickname,
        phone: phone,
        avatarColor: avatarColor,
        online: online ?? this.online,
        avatarPath: avatarPath ?? this.avatarPath,
        hidePhone: hidePhone ?? this.hidePhone,
      );
}