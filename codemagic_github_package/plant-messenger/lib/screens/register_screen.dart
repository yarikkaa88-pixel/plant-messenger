import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/plant_background.dart';
import '../widgets/plant_button.dart';
import '../widgets/plant_input.dart';
import '../widgets/plant_title.dart';
import 'chat_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final result = AuthService.instance.register(
      login: _loginController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
    );

    switch (result) {
      case RegisterResult.success:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const ChatListScreen()),
          (_) => false,
        );
      case RegisterResult.emptyFields:
        setState(() => _errorMessage = 'Заполните все поля');
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
                const SizedBox(height: 16),
                const PlantTitle(),
                const SizedBox(height: 20),
                const PlantSubtitle(
                  text:
                      'Придумайте свой логин и пароль\nи введите номер телефона',
                ),
                const SizedBox(height: 32),
                PlantInput(hint: 'ЛОГИН', controller: _loginController),
                const SizedBox(height: 14),
                PlantInput(
                  hint: 'ПАРОЛЬ',
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 14),
                PlantInput(
                  hint: 'НОМЕР ТЕЛЕФОНА',
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                ),
                const Spacer(),
                if (_errorMessage != null) AuthErrorText(message: _errorMessage!),
                PlantButton(label: 'РЕГИСТРАЦИЯ', onPressed: _submit),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
