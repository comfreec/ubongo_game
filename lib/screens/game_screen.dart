import 'dart:async';
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/puzzle.dart';
import '../models/game_state.dart';
import '../data/puzzles.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_widget.dart';
import '../widgets/timer_widget.dart';
import '../services/sound_service.dart';
import '../services/score_service.dart';

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

  // 조각 수 기준 타이머
  int get _timerSeconds {
    final count = _puzzle.pieceIds.length;
    if (count <= 3) return 90;   // 쉬움
    if (count == 4) return 60;   // 보통
    return 45;                   // 어려움 (5조각 이상)
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
        ScoreService.saveBest(_puzzle.id, _state.remainingSeconds);
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          () {
            final count = _puzzle.pieceIds.length;
            final diff = count <= 3 ? '쉬움' : count == 4 ? '보통' : '어려움';
            return '블록피트  ${_currentIndex + 1}/${widget.puzzles.length}  [$diff]${_isPractice ? "  연습" : ""}';
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
      body: _state.status == GameStatus.playing
          ? _buildGameBody()
          : _buildResultOverlay(),
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
                      puzzle: _state.puzzle,
                      placedPieces: _state.placedPieces,
                      cellSize: cellSize,
                      onDrop: _onDrop,
                      onRemove: _onRemove,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('\uBCF4\uB4DC\uC758 \uC870\uAC01\uC744 \uD0ED\uD558\uBA74 \uC81C\uAC70\uB429\uB2C8\uB2E4',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
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
                          label: '되돌리기',
                          enabled: _undoStack.isNotEmpty,
                          onTap: _undo,
                        ),
                        const SizedBox(width: 12),
                        // 다시 시작
                        _ActionBtn(
                          icon: Icons.refresh,
                          label: '다시',
                          enabled: true,
                          onTap: () => setState(_initGame),
                          color: Colors.greenAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('\uD0ED: \uD68C\uC804  |  \uAE38\uAC8C \uD0ED: \uBC18\uC804  |  \uB4DC\uB798\uADF8: \uBC30\uCE58',
                        style: TextStyle(color: Colors.white54, fontSize: 10)),
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
                        return Center(
                          child: PieceWidget(
                            key: ValueKey(piece.instanceId),
                            piece: current,
                            cellSize: cellSize,
                            onTransform: (transformed) {
                              setState(() => _transformedPieces[piece.instanceId] = transformed);
                            },
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
    final success = _state.status == GameStatus.success;
    final hasNext = _currentIndex < widget.puzzles.length - 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              success ? '\uD83C\uDF89 \uC644\uC131!' : '\u23F0 \uC2DC\uAC04 \uCD08\uACFC!',
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (success) ...[
              Text(
                '\uB0A8\uC740 \uC2DC\uAC04: ${_isPractice ? "-" : "${_state.remainingSeconds}\uCD08"}',
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                hasNext ? '3\uCD08 \uD6C4 \uB2E4\uC74C \uD37C\uC990...' : '\uBAA8\uB4E0 \uD37C\uC990 \uC644\uB8CC!',
                style: const TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ] else
              const Text('\uB2E4\uC74C\uC5D4 \uB354 \uBE60\uB974\uAC8C!',
                  style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(_initGame),
                  icon: const Icon(Icons.refresh),
                  label: const Text('\uB2E4\uC2DC \uB3C4\uC804'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                if (success && hasNext)
                  ElevatedButton.icon(
                    onPressed: _goNextPuzzle,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('\uB2E4\uC74C \uD37C\uC990'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('\uBA54\uC778'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
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
