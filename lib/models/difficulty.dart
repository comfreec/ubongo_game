enum Difficulty {
  easy,
  normal,
  hard;

  String get label {
    switch (this) {
      case Difficulty.easy: return '쉬움';
      case Difficulty.normal: return '보통';
      case Difficulty.hard: return '어려움';
    }
  }

  int get timeSeconds {
    switch (this) {
      case Difficulty.easy: return 90;
      case Difficulty.normal: return 60;
      case Difficulty.hard: return 45;
    }
  }

  int get scoreMultiplier {
    switch (this) {
      case Difficulty.easy: return 1;
      case Difficulty.normal: return 2;
      case Difficulty.hard: return 3;
    }
  }

  // 퍼즐 필터: 조각 수 기준
  bool matchesPieceCount(int count) {
    switch (this) {
      case Difficulty.easy: return count <= 3;
      case Difficulty.normal: return count == 4;
      case Difficulty.hard: return count >= 4;
    }
  }
}
