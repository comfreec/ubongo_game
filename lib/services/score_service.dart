import 'package:shared_preferences/shared_preferences.dart';
import '../models/difficulty.dart';

class ScoreService {
  static const _keyPrefix = 'best_score_';

  static String _key(Difficulty d) => '$_keyPrefix${d.name}';

  /// 점수 계산: 남은 시간 × 난이도 배율 × 10
  static int calcScore(int remainingSeconds, Difficulty difficulty) {
    return remainingSeconds * difficulty.scoreMultiplier * 10;
  }

  static Future<int> getBestScore(Difficulty d) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key(d)) ?? 0;
  }

  /// 새 점수가 최고점이면 저장하고 true 반환
  static Future<bool> updateBestScore(int score, Difficulty d) async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt(_key(d)) ?? 0;
    if (score > best) {
      await prefs.setInt(_key(d), score);
      return true;
    }
    return false;
  }

  static Future<Map<Difficulty, int>> getAllBestScores() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final d in Difficulty.values)
        d: prefs.getInt(_key(d)) ?? 0,
    };
  }
}
