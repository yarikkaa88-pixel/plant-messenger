import 'package:shared_preferences/shared_preferences.dart';

enum LoginResult { success, emptyFields, userNotFound, wrongPassword }

enum RegisterResult { success, emptyFields }

class AuthService {
  AuthService(this._prefs);

  static const _loginKey = 'plant_login';
  static const _passwordKey = 'plant_password';
  static const _phoneKey = 'plant_phone';

  final SharedPreferences _prefs;

  static AuthService? _instance;

  static AuthService get instance {
    final service = _instance;
    if (service == null) {
      throw StateError('AuthService не инициализирован. Вызовите init() в main().');
    }
    return service;
  }

  static Future<void> init() async {
    _instance = AuthService(await SharedPreferences.getInstance());
  }

  bool get isRegistered => _prefs.containsKey(_loginKey);

  String? get savedLogin => _prefs.getString(_loginKey);
  String? get savedPhone => _prefs.getString(_phoneKey);

  RegisterResult register({
    required String login,
    required String password,
    required String phone,
  }) {
    if (login.trim().isEmpty || password.isEmpty || phone.trim().isEmpty) {
      return RegisterResult.emptyFields;
    }

    _prefs.setString(_loginKey, login.trim());
    _prefs.setString(_passwordKey, password);
    _prefs.setString(_phoneKey, phone.trim());
    return RegisterResult.success;
  }

  LoginResult login({required String login, required String password}) {
    if (login.trim().isEmpty || password.isEmpty) {
      return LoginResult.emptyFields;
    }

    final savedLogin = _prefs.getString(_loginKey);
    if (savedLogin == null) {
      return LoginResult.userNotFound;
    }

    if (savedLogin != login.trim()) {
      return LoginResult.userNotFound;
    }

    final savedPassword = _prefs.getString(_passwordKey);
    if (savedPassword != password) {
      return LoginResult.wrongPassword;
    }

    return LoginResult.success;
  }
}
