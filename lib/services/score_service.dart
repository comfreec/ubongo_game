import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  static const _prefix = 'best_';
  static const _completedKey = 'completed_puzzles';

  /// 별점 계산: 남은 시간 기준 (타이머 총 시간 대비)
  static int calcStars(int remainingSeconds, int totalSeconds) {
    if (totalSeconds <= 0) return 3; // 연습 모드
    final ratio = remainingSeconds / totalSeconds;
    if (ratio >= 0.5) return 3;
    if (ratio >= 0.2) return 2;
    return 1;
  }

  /// 퍼즐 최고 기록 저장 (남은 시간 기준, 높을수록 좋음)
  /// 반환값: true = 신기록 갱신
  static Future<bool> saveBest(String puzzleId, int remainingSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$puzzleId';
    final current = prefs.getInt(key) ?? -1;
    bool isNewRecord = false;
    if (remainingSeconds > current) {
      await prefs.setInt(key, remainingSeconds);
      isNewRecord = current != -1; // 이전 기록이 있을 때만 신기록
    }
    // 완료 목록에 추가
    final completed = prefs.getStringList(_completedKey) ?? [];
    if (!completed.contains(puzzleId)) {
      completed.add(puzzleId);
      await prefs.setStringList(_completedKey, completed);
    }
    return isNewRecord;
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
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix) || k == _completedKey).toList();
    for (final k in keys) await prefs.remove(k);
  }

  /// 퍼즐 잠금 여부: 인덱스 기준, 이전 퍼즐 클리어해야 해금
  /// 처음 3개는 항상 열려있음
  static Future<bool> isUnlocked(String puzzleId, int index, List<String> allIds) async {
    if (index < 3) return true;
    final prevId = allIds[index - 1];
    final completed = await getCompleted();
    return completed.contains(prevId);
  }
}
