# -*- coding: utf-8 -*-
code = r"""import 'dart:async';
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/puzzle.dart';
import '../models/game_state.dart';
import '../data/puzzles.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_widget.dart';
import '../widgets/timer_widget.dart';
import '../services/sound_service.dart';

class GameScreen extends StatefulWidget {
  final List<Puzzle> puzzles;
  final int initialIndex;

  const GameScreen({
    super.key,
    required this.puzzles,
    required this.initialIndex,
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
  static const int _totalSeconds = 60;

  Puzzle get _puzzle => widget.puzzles[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initGame();
  }

  void _initGame() {
    _autoNextTimer?.cancel();
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
      remainingSeconds: _totalSeconds,
    );

    _transformedPieces.clear();
    for (final p in pieces) {
      _transformedPieces[p.instanceId] = p;
    }
    _startTimer();
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
      final newPlaced = [
        ..._state.placedPieces,
        PlacedPiece(piece: piece, row: row, col: col),
      ];
      final idx = _state.availablePieces.indexWhere((p) => p.instanceId == piece.instanceId);
      final newAvailable = [..._state.availablePieces];
      if (idx != -1) newAvailable.removeAt(idx);
      _state = _state.copyWith(placedPieces: newPlaced, availablePieces: newAvailable);
      if (_state.isSolved) {
        _timer?.cancel();
        _state = _state.copyWith(status: GameStatus.success);
        SoundService.playSuccess();
        _scheduleAutoNext();
      }
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
          '\uBE14\uB85D\uD53C\uD2B8  ${_currentIndex + 1}/${widget.puzzles.length}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TimerWidget(seconds: _state.remainingSeconds),
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

        // 고정 UI 높이: 안내텍스트(16) + SizedBox(4+8) + 조각영역 최소(120) + 여백(24+8)
        const fixedUI = 16.0 + 12.0 + 120.0 + 32.0;
        final boardAreaH = h - fixedUI;

        // cellSize: 보드가 너비와 높이 안에 딱 맞게
        final cellByW = (w * 0.96) / _puzzle.cols;
        final cellByH = boardAreaH / _puzzle.rows;
        final cellSize = (cellByW < cellByH ? cellByW : cellByH).clamp(24.0, 80.0);

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;

        return Column(
          children: [
            // 보드 영역: 계산된 높이만큼
            SizedBox(
              width: w,
              height: boardH + 8,
              child: Center(
                child: SizedBox(
                  width: boardW,
                  height: boardH,
                  child: BoardWidget(
                    puzzle: _state.puzzle,
                    placedPieces: _state.placedPieces,
                    cellSize: cellSize,
                    onDrop: _onDrop,
                    onRemove: (pp) {
                      if (_state.status != GameStatus.playing) return;
                      SoundService.playRemove();
                      setState(() {
                        final newPlaced = _state.placedPieces.where((p) => p != pp).toList();
                        final newAvailable = [..._state.availablePieces, pp.piece];
                        _state = _state.copyWith(placedPieces: newPlaced, availablePieces: newAvailable);
                      });
                    },
                  ),
                ),
              ),
            ),
            Text(
              '\uBCF4\uB4DC\uC758 \uC870\uAC01\uC744 \uD0ED\uD558\uBA74 \uC81C\uAC70\uB429\uB2C8\uB2E4',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            // 조각 영역: 남은 공간 전부
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\uD0ED: \uD68C\uC804  |  \uAE38\uAC8C \uD0ED: \uBC18\uC804  |  \uB4DC\uB798\uADF8: \uBC30\uCE58',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: _state.availablePieces.map((piece) {
                            final current = _transformedPieces[piece.instanceId] ?? piece;
                            return PieceWidget(
                              key: ValueKey(piece.instanceId),
                              piece: current,
                              cellSize: cellSize,
                              onTransform: (transformed) {
                                setState(() => _transformedPieces[piece.instanceId] = transformed);
                              },
                            );
                          }).toList(),
                        ),
                      ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            success ? '\uD83C\uDF89 \uC644\uC131!' : '\u23F0 \uC2DC\uAC04 \uCD08\uACFC!',
            style: const TextStyle(
                color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            success
                ? (hasNext ? '3\uCD08 \uD6C4 \uB2E4\uC74C \uD37C\uC990\uB85C \uC774\uB3D9\uD569\uB2C8\uB2E4...' : '\uBAA8\uB4E0 \uD37C\uC990 \uC644\uB8CC!')
                : '\uB2E4\uC74C\uC5D4 \uB354 \uBE60\uB974\uAC8C!',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          if (success)
            Text(
              '\uB0A8\uC740 \uC2DC\uAC04: ${_state.remainingSeconds}\uCD08',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => setState(_initGame),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('\uB2E4\uC2DC \uB3C4\uC804'),
              ),
              const SizedBox(width: 12),
              if (success && hasNext)
                ElevatedButton(
                  onPressed: _goNextPuzzle,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text('\uB2E4\uC74C \uD37C\uC990 \u2192'),
                ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                child: const Text('\uBA54\uC778\uC73C\uB85C'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
"""

with open('lib/screens/game_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()
lines = c.splitlines()
print(f"Lines: {len(lines)}")
print(f"Open: {c.count(chr(123))}, Close: {c.count(chr(125))}")
# cellSize 확인
for i, l in enumerate(lines):
    if 'cellSize' in l and 'clamp' in l:
        print(f"Line {i+1}: {l.strip()}")
