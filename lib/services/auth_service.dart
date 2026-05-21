import 'package:shared_preferences/shared_preferences.dart';

import '../models/plant_user.dart';
import 'api_client.dart';
import 'plant_data_service.dart';

enum LoginResult {
  success,
  emptyFields,
  userNotFound,
  wrongPassword,
  networkError,
}

enum RegisterResult {
  success,
  emptyFields,
  nicknameTaken,
  phoneTaken,
  networkError,
}

class AuthService {
  AuthService(this._prefs);

  static const _loginKey = 'plant_login';

  final SharedPreferences _prefs;

  static AuthService? _instance;

  static AuthService get instance {
    final service = _instance;
    if (service == null) {
      throw StateError('AuthService не инициализирован.');
    }
    return service;
  }

  static Future<void> init() async {
    _instance = AuthService(await SharedPreferences.getInstance());
  }

  bool get hasSavedLogin => _prefs.containsKey(_loginKey);
  String? get savedLogin => _prefs.getString(_loginKey);

  Future<RegisterResult> register({
    required String login,
    required String password,
    required String phone,
  }) async {
    if (login.trim().isEmpty || password.isEmpty || phone.trim().isEmpty) {
      return RegisterResult.emptyFields;
    }

    try {
      final data = PlantDataService.instance;
      final response = await data.api.postJson('/api/auth/register', {
        'nickname': login.trim(),
        'password': password,
        'phone': phone.trim(),
      });

      final token = response['token'] as String;
      final user = PlantUser.fromJson(response['user'] as Map<String, dynamic>);
      await data.setSession(token: token, user: user);
      await _prefs.setString(_loginKey, login.trim());
      return RegisterResult.success;
    } on ApiException catch (e) {
      return switch (e.code) {
        'nickname_taken' => RegisterResult.nicknameTaken,
        'phone_taken' => RegisterResult.phoneTaken,
        _ => RegisterResult.networkError,
      };
    } catch (_) {
      return RegisterResult.networkError;
    }
  }

  Future<LoginResult> login({
    required String login,
    required String password,
  }) async {
    if (login.trim().isEmpty || password.isEmpty) {
      return LoginResult.emptyFields;
    }

    try {
      final data = PlantDataService.instance;
      final response = await data.api.postJson('/api/auth/login', {
        'nickname': login.trim(),
        'password': password,
      });

      final token = response['token'] as String;
      final user = PlantUser.fromJson(response['user'] as Map<String, dynamic>);
      await data.setSession(token: token, user: user);
      await _prefs.setString(_loginKey, login.trim());
      return LoginResult.success;
    } on ApiException catch (e) {
      return switch (e.code) {
        'user_not_found' => LoginResult.userNotFound,
        'wrong_password' => LoginResult.wrongPassword,
        _ => LoginResult.networkError,
      };
    } catch (_) {
      return LoginResult.networkError;
    }
  }

  Future<void> logout() async {
    await PlantDataService.instance.clearSession();
  }
}
