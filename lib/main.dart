import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BlockFitApp());
}

class BlockFitApp extends StatelessWidget {
  const BlockFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '블록피트',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.blueAccent,
          surface: const Color(0xFF1A1A2E),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
