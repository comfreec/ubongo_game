import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static const _prefix = 'best_';
  static const _completedKey = 'completed_puzzles';

  /// 퍼즐 최고 기록 저장 (남은 시간 기준, 높을수록 좋음)
  static Future<void> saveBest(String puzzleId, int remainingSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$puzzleId';
    final current = prefs.getInt(key) ?? -1;
    if (remainingSeconds > current) {
      await prefs.setInt(key, remainingSeconds);
    }
    // 완료 목록에 추가
    final completed = prefs.getStringList(_completedKey) ?? [];
    if (!completed.contains(puzzleId)) {
      completed.add(puzzleId);
      await prefs.setStringList(_completedKey, completed);
    }
  }

  /// 퍼즐 최고 기록 로드
  static Future<int?> getBest(String puzzleId) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt('$_prefix$puzzleId');
    return v == -1 ? null : v;
  }

  /// 완료한 퍼즐 ID 목록
  static Future<Set<String>> getCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_completedKey) ?? []).toSet();
  }

  /// 모든 기록 초기화
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix) || k == _completedKey);
    for (final k in keys) await prefs.remove(k);
  }
}
