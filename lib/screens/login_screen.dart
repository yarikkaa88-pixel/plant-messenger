import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/plant_background.dart';
import '../widgets/plant_button.dart';
import '../widgets/plant_input.dart';
import '../widgets/plant_title.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _loading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await AuthService.instance.login(
      login: _loginController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    switch (result) {
      case LoginResult.success:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      case LoginResult.emptyFields:
        setState(() => _errorMessage = 'Введите логин и пароль');
      case LoginResult.userNotFound:
        setState(() => _errorMessage = 'Неверный логин или аккаунт не найден');
      case LoginResult.wrongPassword:
        setState(() => _errorMessage = 'Неверный пароль');
      case LoginResult.networkError:
        setState(
          () => _errorMessage =
              'Не удалось подключиться к серверу.\nЗапустите backend (npm start)',
        );
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
                PlantButton(
                  label: _loading ? 'ВХОД...' : 'ВХОД',
                  onPressed: _loading ? () {} : _submit,
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
