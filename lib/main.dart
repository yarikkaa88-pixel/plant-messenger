import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';
import 'services/plant_data_service.dart';
import 'theme/plant_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlantDataService.init();
  await AuthService.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const PlantApp());
}

class PlantApp extends StatelessWidget {
  const PlantApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = PlantDataService.instance.currentUser != null;

    return MaterialApp(
      title: 'PLANT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: PlantColors.lime,
        colorScheme: ColorScheme.fromSeed(
          seedColor: PlantColors.header,
          primary: PlantColors.header,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: PlantColors.listTile,
          indicatorColor: PlantColors.header.withValues(alpha: 0.2),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            final selected = states.contains(MaterialState.selected);
            return GoogleFonts.nunito(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? PlantColors.darkGreen : PlantColors.forest,
            );
          }),
        ),
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      home: isLoggedIn ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}
