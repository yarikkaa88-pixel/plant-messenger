import 'dart:convert';

import 'package:flutter/material.dart';

class PlantUser {
  const PlantUser({
    required this.id,
    required this.nickname,
    required this.phone,
    this.avatarColor = 0xFF2D6B32,
    this.online = false,
    this.avatarPath,
    this.hidePhone = false,
    this.coins = 0,
  });

  final String id;
  final String nickname;
  final String phone;
  final int avatarColor;
  final bool online;
  final String? avatarPath;
  final bool hidePhone;
  final int coins;

  String get displayPhone => hidePhone ? phone.replaceRange(4, 7, '***') : phone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'phone': phone,
        'avatarColor': avatarColor,
        'online': online,
        'avatarPath': avatarPath,
        'hidePhone': hidePhone,
        'coins': coins,
      };

  factory PlantUser.fromJson(Map<String, dynamic> json) => PlantUser(
        id: json['id'] as String,
        nickname: json['nickname'] as String,
        phone: json['phone'] as String,
        avatarColor: json['avatarColor'] as int? ?? 0xFF2D6B32,
        online: json['online'] as bool? ?? false,
        avatarPath: json['avatarPath'] as String?,
        hidePhone: json['hidePhone'] as bool? ?? false,
        coins: json['coins'] as int? ?? 0,
      );

  PlantUser copyWith({
    bool? online,
    String? avatarPath,
    bool? hidePhone,
    int? coins,
  }) =>
      PlantUser(
        id: id,
        nickname: nickname,
        phone: phone,
        avatarColor: avatarColor,
        online: online ?? this.online,
        avatarPath: avatarPath ?? this.avatarPath,
        hidePhone: hidePhone ?? this.hidePhone,
        coins: coins ?? this.coins,
      );

  ImageProvider avatarProvider() {
    if (avatarPath == null) return const AssetImage('default_avatar.png');
    if (avatarPath!.startsWith('data:')) {
      final base64 = avatarPath!.split(',').last;
      return MemoryImage(base64Decode(base64));
    }
    if (avatarPath!.startsWith('http')) {
      return NetworkImage(avatarPath!);
    }
    return const AssetImage('default_avatar.png');
  }
}