import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._();
  static SettingsService get instance => _instance;
  SettingsService._();

  bool _soundEnabled = true;
  bool _colorBlindMode = false;

  bool get soundEnabled => _soundEnabled;
  bool get colorBlindMode => _colorBlindMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    _colorBlindMode = prefs.getBool('color_blind_mode') ?? false;
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool v) async {
    _soundEnabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', v);
    notifyListeners();
  }

  Future<void> setColorBlindMode(bool v) async {
    _colorBlindMode = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('color_blind_mode', v);
    notifyListeners();
  }

  /// 색맹 모드용 색상 팔레트 (패턴 구분 가능한 색상)
  static const List<Color> colorBlindPalette = [
    Color(0xFF0077BB), // 파랑
    Color(0xFFEE7733), // 주황
    Color(0xFF009988), // 청록
    Color(0xFFCC3311), // 빨강
    Color(0xFF33BBEE), // 하늘
    Color(0xFFEE3377), // 분홍
    Color(0xFFBBBBBB), // 회색
  ];
}
