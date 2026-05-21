import 'package:flutter/material.dart';

class DefaultAvatar extends StatelessWidget {
  const DefaultAvatar({super.key, this.radius = 20});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: const AssetImage('default_avatar.png'),
      backgroundColor: Colors.transparent,
    );
  }
}
