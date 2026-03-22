// 한국어 고정 문자열
class S {
  const S();

  // ── 앱 공통 ──
  String get appName => '블록피트';
  String get appSubtitle => '조각을 맞춰 보드를 채우세요';

  // ── 홈 화면 ──
  String get totalProgress => '전체 진행률';
  String get completed => '완료';
  String get easy => '쉬움';
  String get medium => '보통';
  String get hard => '어려움';
  String get all => '전체';
  String get puzzle => '퍼즐';
  String get pieces => '조각';
  String piecesCount(int n) => '조각 ${n}개';
  String get lockedHint => '이전 퍼즐을 클리어하세요';

  // ── 게임 화면 ──
  String get diffEasy => easy;
  String get diffMedium => medium;
  String get diffHard => hard;
  String get practice => '연습';
  String get undo => '되돌리기';
  String get hint => '힌트';
  String get restart => '다시';
  String get tapRotate => '탭: 회전  |  길게 탭: 반전  |  드래그: 배치';
  String get success => '🎉 완성!';
  String get timeOver => '⏰ 시간 초과!';
  String get remainingTime => '남은 시간';
  String get newRecord => '🏆 신기록!';
  String get tryFaster => '다음엔 더 빠르게!';
  String get allPuzzlesDone => '모든 퍼즐 완료!';
  String get retryBtn => '다시 도전';
  String get nextPuzzle => '다음 퍼즐';
  String get homeBtn => '메인';
  String get secAfterNext => '초 후 다음 퍼즐';
  String get cancel => '취소';
  String get hintNotFound => '힌트를 찾을 수 없습니다';
  String get showAnswer => '정답 보기';
  String get showAnswerConfirm => '정답을 보면 이번 퍼즐은 별점 없이 완료됩니다.\n계속할까요?';
  String get leaveTitle => '게임 나가기';
  String get leaveMsg => '진행 중인 게임이 종료됩니다.\n정말 나가시겠어요?';
  String get keepPlaying => '계속하기';
  String get leaveBtn => '나가기';
  String get close => '닫기';

  // ── 설정 화면 ──
  String get settings => '설정';
  String get game => '게임';
  String get soundFx => '효과음';
  String get soundFxDesc => '배치, 완료, 실패 효과음';
  String get colorBlind => '색맹 모드';
  String get colorBlindDesc => '색상 구분이 쉬운 팔레트로 변경';
  String get data => '데이터';
  String get tutorialReset => '튜토리얼 다시보기';
  String get tutorialResetDesc => '다음 앱 시작 시 튜토리얼 표시';
  String get tutorialResetTitle => '튜토리얼 초기화';
  String get tutorialResetMsg => '다음에 앱을 시작하면\n튜토리얼이 다시 표시됩니다.';
  String get confirm => '확인';
  String get resetRecords => '기록 초기화';
  String get resetRecordsDesc => '모든 클리어 기록과 별점 삭제';
  String get resetConfirmMsg => '모든 클리어 기록과 별점이 삭제됩니다.\n이 작업은 되돌릴 수 없어요.';
  String get resetDone => '기록이 초기화되었습니다.';
  String get appInfo => '앱 정보';
  String get version => '버전';
  String get versionDesc => '1.0.0';
  String get versionDialogDesc => '조각을 맞춰 보드를 채우는\n퍼즐 게임입니다.';

  // ── 전체 완료 ──
  String get allClearTitle => '전체 완료!';
  String get allClearMsg => '모든 퍼즐을 클리어했습니다!';
  String get continueBtn => '계속하기';
  String ratingMsg(int stars, int max) {
    final ratio = max > 0 ? stars / max : 0.0;
    if (ratio >= 0.9) return '완벽한 플레이어! ✨';
    if (ratio >= 0.7) return '훌륭한 실력이에요! 🌟';
    if (ratio >= 0.5) return '잘 하셨어요! 👍';
    return '도전을 완료했습니다! 🎉';
  }

  // ── 튜토리얼 ──
  String get tutStep1Title => '드래그로 배치';
  String get tutStep1Desc => '조각을 꾹 누른 채 드래그해서\n보드의 빈 칸 위에 올려놓으세요.\n초록색이면 배치 가능!';
  String get tutStep2Title => '탭으로 회전';
  String get tutStep2Desc => '조각을 한 번 탭하면\n시계 방향으로 90° 회전합니다.\n원하는 방향으로 맞춰보세요.';
  String get tutStep3Title => '길게 탭으로 반전';
  String get tutStep3Desc => '조각을 길게 누르면\n좌우로 뒤집힙니다.\n회전과 반전을 조합해보세요!';
  String get tutStep4Title => '보드를 완성하세요';
  String get tutStep4Desc => '모든 조각을 빈틈없이 채우면\n퍼즐 클리어! 남은 시간이 많을수록\n별점이 높아요 ⭐⭐⭐';
  String get tutNext => '다음 →';
  String get tutStart => '시작하기 🎮';
  String get tutSkip => '건너뛰기';
  String get tutProgress => '튜토리얼';

  // ── 스플래시 ──
  String get dragLabel => '조각';
  String get boardLabel => '보드';
  String get tapRotateLabel => '탭 → 90° 회전';
  String get longTapFlipLabel => '길게 탭 → 좌우 반전';
  String get clearLabel => '모두 채우면 클리어! ⭐';

  static const S _instance = S();
  static S of(context) => _instance;
  static S get current => _instance;
}
