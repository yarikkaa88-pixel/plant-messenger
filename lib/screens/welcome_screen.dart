import 'package:flutter/material.dart';

import '../widgets/plant_background.dart';
import '../widgets/plant_button.dart';
import '../widgets/plant_title.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlantBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 72),
                const PlantTitle(),
                const SizedBox(height: 28),
                const PlantSubtitle(
                  text: 'Здравствуйте войдите\nили зарегистрируйтесь',
                ),
                const Spacer(),
                PlantButton(
                  label: 'ВХОД',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                PlantButton(
                  label: 'РЕГИСТРАЦИЯ',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
