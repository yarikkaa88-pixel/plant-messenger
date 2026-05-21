import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/services/auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('register saves and login validates password', () async {
    await AuthService.init();
    final auth = AuthService.instance;

    expect(
      auth.register(login: 'user1', password: 'pass123', phone: '+79001234567'),
      RegisterResult.success,
    );

    expect(
      auth.login(login: 'user1', password: 'wrong'),
      LoginResult.wrongPassword,
    );
    expect(
      auth.login(login: 'user1', password: 'pass123'),
      LoginResult.success,
    );
  });

  test('login fails for unknown user', () async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.init();

    expect(
      AuthService.instance.login(login: 'nobody', password: 'x'),
      LoginResult.userNotFound,
    );
  });
}
