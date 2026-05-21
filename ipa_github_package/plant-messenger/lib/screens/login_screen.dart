import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/plant_background.dart';
import '../widgets/plant_button.dart';
import '../widgets/plant_input.dart';
import '../widgets/plant_title.dart';
import 'chat_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final result = AuthService.instance.login(
      login: _loginController.text,
      password: _passwordController.text,
    );

    switch (result) {
      case LoginResult.success:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const ChatListScreen()),
          (_) => false,
        );
      case LoginResult.emptyFields:
        setState(() => _errorMessage = 'Введите логин и пароль');
      case LoginResult.userNotFound:
        setState(
          () => _errorMessage = AuthService.instance.isRegistered
              ? 'Неверный логин'
              : 'Аккаунт не найден. Сначала зарегистрируйтесь',
        );
      case LoginResult.wrongPassword:
        setState(() => _errorMessage = 'Неверный пароль');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlantBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                    color: const Color(0xFF1A4A1A),
                  ),
                ),
                const SizedBox(height: 24),
                const PlantTitle(),
                const SizedBox(height: 28),
                const PlantSubtitle(text: 'Введите свой логин и пароль'),
                const SizedBox(height: 40),
                PlantInput(hint: 'ЛОГИН', controller: _loginController),
                const SizedBox(height: 14),
                PlantInput(
                  hint: 'ПАРОЛЬ',
                  obscureText: true,
                  controller: _passwordController,
                ),
                const Spacer(),
                if (_errorMessage != null) AuthErrorText(message: _errorMessage!),
                PlantButton(label: 'ВХОД', onPressed: _submit),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
