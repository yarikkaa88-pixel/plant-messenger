import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/plant_data_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PLANT app launches welcome screen', (tester) async {
    await PlantDataService.init();
    await AuthService.init();
    await tester.pumpWidget(const PlantApp());
    expect(find.text('PLANT'), findsOneWidget);
    expect(find.text('ВХОД'), findsWidgets);
    expect(find.text('РЕГИСТРАЦИЯ'), findsOneWidget);
  });
}
