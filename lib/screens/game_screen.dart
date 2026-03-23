import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/piece.dart';
import '../models/puzzle.dart';
import '../models/game_state.dart';
import '../data/puzzles.dart';
import '../data/puzzle_solver.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_widget.dart';
import '../widgets/timer_widget.dart';
import '../widgets/confetti_widget.dart';
import '../services/sound_service.dart';
import '../services/score_service.dart';
import '../l10n/app_strings.dart';

class GameScreen extends StatefulWidget {
  final List<Puzzle> puzzles;
  final int initialIndex;
  final bool practiceMode; // 연습 모드: 타이머 없음

  const GameScreen({
    super.key,
    required this.puzzles,
    required this.initialIndex,
    this.practiceMode = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int _currentIndex;
  late GameState _state;
  Timer? _timer;
  Timer? _autoNextTimer;

  final Map<String, Piece> _transformedPieces = {};

  // undo 스택: 각 원소는 (placedPieces, availablePieces) 스냅샷
  final List<({List<PlacedPiece> placed, List<Piece> available})> _undoStack = [];

  // 신기록 여부
  bool _isNewRecord = false;

  // 정답 보기 애니메이션 진행 중
  bool _isShowingAnswer = false;

  // 날아가는 조각 오버레이 상태
  _FlyingPieceData? _flyingPiece;

  // 보드 GlobalKey (위치 계산용)
  final GlobalKey _boardKey = GlobalKey();
  // 조각 패널 GlobalKey들 (instanceId → key)
  final Map<String, GlobalKey> _pieceKeys = {};

  // 조각 수 기준 타이머
  int get _timerSeconds {
    final count = _puzzle.pieceIds.length;
    if (count <= 3) return 60;   // 쉬움
    if (count == 4) return 90;   // 보통
    return 120;                  // 어려움 (5조각 이상)
  }

  Puzzle get _puzzle => widget.puzzles[_currentIndex];
  bool get _isPractice => widget.practiceMode;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initGame();
  }

  void _initGame() {
    _autoNextTimer?.cancel();
    _undoStack.clear();
    _isNewRecord = false;
    _isShowingAnswer = false;

    int counter = 0;
    final pieces = _puzzle.pieceIds.map((id) {
      final base = allPieces[id]!;
      final iid = '${id}_${counter++}';
      return Piece(id: base.id, instanceId: iid, cells: base.cells, color: base.color);
    }).toList();

    _state = GameState(
      puzzle: _puzzle,
      availablePieces: pieces,
      placedPieces: [],
      status: GameStatus.playing,
      remainingSeconds: _isPractice ? 9999 : _timerSeconds,
    );

    _transformedPieces.clear();
    for (final p in pieces) {
      _transformedPieces[p.instanceId] = p;
      _pieceKeys[p.instanceId] = GlobalKey();
    }

    if (!_isPractice) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final newSecs = _state.remainingSeconds - 1;
        if (newSecs <= 0) {
          _state = _state.copyWith(remainingSeconds: 0, status: GameStatus.failed);
          _timer?.cancel();
          SoundService.playFail();
        } else {
          _state = _state.copyWith(remainingSeconds: newSecs);
        }
      });
    });
  }

  void _onDrop(Piece piece, int row, int col) {
    HapticFeedback.lightImpact();
    SoundService.playPlace();
    setState(() {
      // undo 스택에 현재 상태 저장
      _undoStack.add((
        placed: List.from(_state.placedPieces),
        available: List.from(_state.availablePieces),
      ));

      final newPlaced = [..._state.placedPieces, PlacedPiece(piece: piece, row: row, col: col)];
      final newAvailable = List<Piece>.from(_state.availablePieces)
        ..removeWhere((p) => p.instanceId == piece.instanceId);

      _state = _state.copyWith(placedPieces: newPlaced, availablePieces: newAvailable);

      if (_state.isSolved) {
        _timer?.cancel();
        _state = _state.copyWith(status: GameStatus.success);
        SoundService.playSuccess();
        ScoreService.saveBest(_puzzle.id, _state.remainingSeconds).then((isNew) {
          if (mounted && isNew) setState(() => _isNewRecord = true);
        });
        _scheduleAutoNext();
      }
    });
  }

  void _onRemove(PlacedPiece pp) {
    if (_state.status != GameStatus.playing) return;
    SoundService.playRemove();
    setState(() {
      _undoStack.add((
        placed: List.from(_state.placedPieces),
        available: List.from(_state.availablePieces),
      ));
      final newPlaced = _state.placedPieces.where((p) => p != pp).toList();
      final newAvailable = [..._state.availablePieces, pp.piece];
      _state = _state.copyWith(placedPieces: newPlaced, availablePieces: newAvailable);
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    SoundService.playRemove();
    setState(() {
      final snap = _undoStack.removeLast();
      _state = _state.copyWith(
        placedPieces: snap.placed,
        availablePieces: snap.available,
      );
    });
  }

  Future<void> _showAnswer() async {
    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        final s = S.of(context);
        return AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(s.showAnswer,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(s.showAnswerConfirm,
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel, style: const TextStyle(color: Colors.blueAccent)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white),
              child: Text(s.showAnswer),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) return;

    // 현재 배치된 조각 모두 제거하고 솔버 실행
    final currentPieces = _state.availablePieces.toList()
      ..addAll(_state.placedPieces.map((pp) => pp.piece));

    final solution = findSolution(_puzzle, currentPieces);
    if (solution == null || !mounted) return;

    // 타이머 정지
    _timer?.cancel();
    setState(() {
      _isShowingAnswer = true;
      _state = _state.copyWith(placedPieces: [], availablePieces: currentPieces);
    });

    // 레이아웃 반영 대기
    await Future.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    for (final placement in solution) {
      if (!mounted) return;

      // 조각 찾기
      final piece = _state.availablePieces.firstWhere(
        (p) => p.instanceId == placement.instanceId,
        orElse: () => _state.availablePieces.first,
      );
      final shapedPiece = Piece(
        id: piece.id,
        instanceId: piece.instanceId,
        cells: placement.cells,
        color: piece.color,
      );

      // 시작 위치: 조각 패널에서 글로벌 좌표
      Offset startGlobal = const Offset(80, 500);
      final pieceKey = _pieceKeys[piece.instanceId];
      if (pieceKey?.currentContext != null) {
        final box = pieceKey!.currentContext!.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          startGlobal = box.localToGlobal(Offset.zero);
        }
      }

      // 끝 위치: 보드에서 글로벌 좌표
      Offset endGlobal = const Offset(80, 100);
      double cellSize = 40.0;
      if (_boardKey.currentContext != null) {
        final boardBox = _boardKey.currentContext!.findRenderObject() as RenderBox?;
        if (boardBox != null && boardBox.hasSize) {
          cellSize = boardBox.size.width / _puzzle.cols;
          final boardOrigin = boardBox.localToGlobal(const Offset(4, 4));
          endGlobal = boardOrigin + Offset(
            placement.col * cellSize,
            placement.row * cellSize,
          );
        }
      }

      final pieceCellSize = cellSize;

      // Overlay로 날아가는 조각 표시
      OverlayEntry? entry;
      entry = OverlayEntry(
        builder: (_) => _FlyingPieceOverlay(
          data: _FlyingPieceData(
            piece: shapedPiece,
            startOffset: startGlobal,
            endOffset: endGlobal,
            cellSize: pieceCellSize,
          ),
          onDone: () => entry?.remove(),
        ),
      );

      // 패널에서 해당 조각 숨김
      setState(() { _flyingPiece = _FlyingPieceData(
        piece: shapedPiece,
        startOffset: startGlobal,
        endOffset: endGlobal,
        cellSize: pieceCellSize,
      ); });

      Overlay.of(context).insert(entry);

      // 애니메이션 시간 대기 (480ms)
      await Future.delayed(const Duration(milliseconds: 530));
      if (!mounted) return;

      // 조각 보드에 배치
      SoundService.playPlace();
      setState(() {
        _flyingPiece = null;
        final newPlaced = [..._state.placedPieces,
          PlacedPiece(piece: shapedPiece, row: placement.row, col: placement.col)];
        final newAvailable = List<Piece>.from(_state.availablePieces)
          ..removeWhere((p) => p.instanceId == piece.instanceId);
        _state = _state.copyWith(placedPieces: newPlaced, availablePieces: newAvailable);
      });

      await Future.delayed(const Duration(milliseconds: 120));
    }

    // 완료 처리
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _isShowingAnswer = false;
      _flyingPiece = null;
      _state = _state.copyWith(status: GameStatus.success, remainingSeconds: 0);
      SoundService.playSuccess();
    });
  }

  void _scheduleAutoNext() {
    final hasNext = _currentIndex < widget.puzzles.length - 1;
    if (!hasNext) return;
    _autoNextTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _initGame();
      });
    });
  }

  void _goNextPuzzle() {
    if (_currentIndex >= widget.puzzles.length - 1) {
      Navigator.pop(context);
      return;
    }
    _autoNextTimer?.cancel();
    setState(() {
      _currentIndex++;
      _initGame();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _autoNextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_state.status != GameStatus.playing) {
          Navigator.pop(context);
          return;
        }
        final leave = await showDialog<bool>(
          context: context,
          builder: (_) {
            final s = S.of(context);
            return AlertDialog(
              backgroundColor: const Color(0xFF16213E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(s.leaveTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Text(s.leaveMsg, style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(s.keepPlaying, style: const TextStyle(color: Colors.blueAccent)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  child: Text(s.leaveBtn),
                ),
              ],
            );
          },
        );
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            () {
              final s = S.of(context);
              final count = _puzzle.pieceIds.length;
              final diff = count <= 3 ? s.diffEasy : count == 4 ? s.diffMedium : s.diffHard;
              return '${s.appName}  ${_currentIndex + 1}/${widget.puzzles.length}  [$diff]${_isPractice ? "  ${s.practice}" : ""}';
            }(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (!_isPractice)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TimerWidget(seconds: _state.remainingSeconds),
              ),
            if (_isPractice)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.self_improvement, color: Colors.greenAccent),
              ),
          ],
        ),
        body: Stack(
          children: [
            _state.status == GameStatus.playing
                ? _buildGameBody()
                : _buildResultOverlay(),
            ConfettiOverlay(active: _state.status == GameStatus.success),
            if (!_isPractice && _state.status == GameStatus.playing &&
                _state.remainingSeconds <= 10)
              _DangerBorder(seconds: _state.remainingSeconds),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        const fixedUI = 73.0;

        int maxPieceRows = 1;
        int maxPieceCols = 1;
        final pieceCount = _puzzle.pieceIds.length;
        for (final id in _puzzle.pieceIds) {
          final p = allPieces[id]!;
          if (p.maxRow + 1 > maxPieceRows) maxPieceRows = p.maxRow + 1;
          if (p.maxCol + 1 > maxPieceCols) maxPieceCols = p.maxCol + 1;
        }

        final gridRows = ((pieceCount + 1) ~/ 2);
        const rowSpacing = 8.0;

        double totalH(double cs) {
          final boardH = cs * _puzzle.rows;
          final cellH = cs * maxPieceRows + 32;
          final gridH = gridRows * cellH + (gridRows - 1) * rowSpacing;
          return boardH + gridH + fixedUI;
        }

        final cBoardW = (w * 0.94) / _puzzle.cols;
        final cPieceW = (w - 26) / 2 / maxPieceCols;
        final hiMax = cBoardW < cPieceW ? cBoardW : cPieceW;

        double lo = 16, hi = hiMax;
        for (int i = 0; i < 30; i++) {
          final mid = (lo + hi) / 2;
          if (totalH(mid) <= h) lo = mid;
          else hi = mid;
        }
        final cellSize = lo;

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;
        final pieceCellH = cellSize * maxPieceRows + 32;

        return Column(
          children: [
            SizedBox(
              width: w,
              height: boardH + 15,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: boardW,
                    height: boardH,
                    child: BoardWidget(
                      key: _boardKey,
                      puzzle: _state.puzzle,
                      placedPieces: _state.placedPieces,
                      cellSize: cellSize,
                      onDrop: _onDrop,
                      onRemove: _onRemove,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // 액션 버튼 행
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Undo
                        _ActionBtn(
                          icon: Icons.undo,
                          label: S.of(context).undo,
                          enabled: _undoStack.isNotEmpty && !_isShowingAnswer,
                          onTap: _undo,
                        ),
                        const SizedBox(width: 8),
                        // 다시 시작
                        _ActionBtn(
                          icon: Icons.refresh,
                          label: S.of(context).restart,
                          enabled: !_isShowingAnswer,
                          onTap: () => setState(_initGame),
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 8),
                        // 정답 보기
                        _ActionBtn(
                          icon: Icons.lightbulb_outline,
                          label: S.of(context).showAnswer,
                          enabled: !_isShowingAnswer,
                          onTap: _showAnswer,
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(S.of(context).tapRotate,
                        style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 4),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: rowSpacing,
                        crossAxisSpacing: 10,
                        mainAxisExtent: pieceCellH,
                      ),
                      itemCount: _state.availablePieces.length,
                      itemBuilder: (context, i) {
                        final piece = _state.availablePieces[i];
                        final current = _transformedPieces[piece.instanceId] ?? piece;
                        final isFlying = _flyingPiece?.piece.instanceId == piece.instanceId;
                        _pieceKeys.putIfAbsent(piece.instanceId, () => GlobalKey());
                        return Center(
                          child: Opacity(
                            opacity: isFlying ? 0.0 : 1.0,
                            child: PieceWidget(
                              key: _pieceKeys[piece.instanceId],
                              piece: current,
                              cellSize: cellSize,
                              onTransform: (transformed) {
                                setState(() => _transformedPieces[piece.instanceId] = transformed);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultOverlay() {
    final s = S.of(context);
    final success = _state.status == GameStatus.success;
    final hasNext = _currentIndex < widget.puzzles.length - 1;
    final stars = success
        ? ScoreService.calcStars(_state.remainingSeconds, _timerSeconds)
        : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              success ? s.success : s.timeOver,
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (success) ...[
              // 별점 애니메이션
              _AnimatedStars(stars: stars),
              const SizedBox(height: 8),
              // 신기록 배지
              if (_isNewRecord)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 12)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(s.newRecord,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '${s.remainingTime}: ${_isPractice ? "-" : "${_state.remainingSeconds}s"}',
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),
              const SizedBox(height: 8),
              if (hasNext)
                _AutoNextCountdown(
                  onCancel: () {
                    _autoNextTimer?.cancel();
                    setState(() {});
                  },
                )
              else
                Text(s.allPuzzlesDone,
                    style: const TextStyle(color: Colors.white54, fontSize: 16)),
            ] else
              Text(s.tryFaster,
                  style: const TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(_initGame),
                  icon: const Icon(Icons.refresh),
                  label: Text(s.retryBtn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (success && hasNext)
                  ElevatedButton.icon(
                    onPressed: _goNextPuzzle,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(s.nextPuzzle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    _autoNextTimer?.cancel();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.home),
                  label: Text(s.homeBtn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 화면 테두리 위험 펄스 효과
class _DangerBorder extends StatefulWidget {
  final int seconds;
  const _DangerBorder({required this.seconds});

  @override
  State<_DangerBorder> createState() => _DangerBorderState();
}

class _DangerBorderState extends State<_DangerBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red.withValues(alpha: _anim.value),
              width: 4,
            ),
          ),
        ),
      ),
    );
  }
}

/// 별점 하나씩 튀어나오는 애니메이션
class _AnimatedStars extends StatefulWidget {
  final int stars;
  const _AnimatedStars({required this.stars});

  @override
  State<_AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<_AnimatedStars>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>> _scales = [];
  final List<Animation<double>> _opacities = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      _ctrls.add(ctrl);
      _scales.add(TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 60),
        TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 40),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut)));
      _opacities.add(Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: ctrl, curve: const Interval(0.0, 0.4)),
      ));
      Future.delayed(Duration(milliseconds: 300 + i * 250), () {
        if (mounted) ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _ctrls[i],
        builder: (_, __) => Opacity(
          opacity: _opacities[i].value,
          child: Transform.scale(
            scale: _scales[i].value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                i < widget.stars ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < widget.stars ? Colors.amber : Colors.white24,
                size: 52,
                shadows: i < widget.stars
                    ? [Shadow(color: Colors.amber.withValues(alpha: 0.6), blurRadius: 16)]
                    : null,
              ),
            ),
          ),
        ),
      )),
    );
  }
}

/// 자동 넘어가기 카운트다운 + 취소 버튼
class _AutoNextCountdown extends StatefulWidget {
  final VoidCallback onCancel;
  const _AutoNextCountdown({required this.onCancel});

  @override
  State<_AutoNextCountdown> createState() => _AutoNextCountdownState();
}

class _AutoNextCountdownState extends State<_AutoNextCountdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final remaining = (3 - (_ctrl.value * 3)).ceil();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                value: 1 - _ctrl.value,
                strokeWidth: 3,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
            const SizedBox(width: 10),
            Text('$remaining${s.secAfterNext}',
                style: const TextStyle(color: Colors.white54, fontSize: 15)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                _ctrl.stop();
                widget.onCancel();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(s.cancel,
                    style: const TextStyle(color: Colors.white60, fontSize: 13)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── 날아가는 조각 데이터 ──
class _FlyingPieceData {
  final Piece piece;
  final Offset startOffset; // 글로벌 좌표
  final Offset endOffset;   // 글로벌 좌표
  final double cellSize;

  _FlyingPieceData({
    required this.piece,
    required this.startOffset,
    required this.endOffset,
    required this.cellSize,
  });
}

// ── 날아가는 조각 오버레이 ──
class _FlyingPieceOverlay extends StatefulWidget {
  final _FlyingPieceData data;
  final VoidCallback onDone;
  const _FlyingPieceOverlay({required this.data, required this.onDone});

  @override
  State<_FlyingPieceOverlay> createState() => _FlyingPieceOverlayState();
}

class _FlyingPieceOverlayState extends State<_FlyingPieceOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _posAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _posAnim = Tween<Offset>(
      begin: widget.data.startOffset,
      end: widget.data.endOffset,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final pieceW = (d.piece.maxCol + 1) * d.cellSize;
    final pieceH = (d.piece.maxRow + 1) * d.cellSize;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final pos = _posAnim.value;
        return Positioned(
          left: pos.dx,
          top: pos.dy,
          child: IgnorePointer(
            child: Transform.scale(
              scale: _scaleAnim.value,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: pieceW,
                height: pieceH,
                child: CustomPaint(
                  painter: _FlyingPiecePainter(d.piece, d.cellSize),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlyingPiecePainter extends CustomPainter {
  final Piece piece;
  final double cellSize;
  _FlyingPiecePainter(this.piece, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final margin = cellSize * 0.04;
    final radius = cellSize * 0.18;

    for (final c in piece.cells) {
      final rect = Rect.fromLTWH(
        c.col * cellSize + margin,
        c.row * cellSize + margin,
        cellSize - margin * 2,
        cellSize - margin * 2,
      );
      final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

      // 그림자
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(rRect.shift(const Offset(0, 3)), shadowPaint);

      // 조각 색상
      final hsl = HSLColor.fromColor(piece.color);
      final highlight = hsl.withLightness((hsl.lightness + 0.25).clamp(0.0, 1.0)).toColor();
      final shadow = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, piece.color, shadow],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);
      canvas.drawRRect(rRect, paint);

      // 하이라이트
      final hlPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            c.col * cellSize + margin + cellSize * 0.08,
            c.row * cellSize + margin + cellSize * 0.06,
            cellSize * 0.35,
            cellSize * 0.12,
          ),
          Radius.circular(cellSize * 0.06),
        ),
        hlPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_FlyingPiecePainter old) => false;
}
