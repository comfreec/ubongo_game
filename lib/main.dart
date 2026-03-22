import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService.instance.load();
  runApp(const BlockFitApp());
}

class BlockFitApp extends StatelessWidget {
  const BlockFitApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BlockFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: const Color(0xFF1A1A2E),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
