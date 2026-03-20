import 'dart:async';
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/puzzle.dart';
import '../models/game_state.dart';
import '../data/puzzles.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_widget.dart';
import '../widgets/timer_widget.dart';

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
  static const double _cellSize = 40.0;

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
        } else {
          _state = _state.copyWith(remainingSeconds: newSecs);
        }
      });
    });
  }

  void _onDrop(Piece piece, int row, int col) {
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
          '블록피트  ${_currentIndex + 1}/${widget.puzzles.length}',
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
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Center(
            child: BoardWidget(
              puzzle: _state.puzzle,
              placedPieces: _state.placedPieces,
              cellSize: _cellSize,
              onDrop: _onDrop,
              onRemove: (pp) {
                if (_state.status != GameStatus.playing) return;
                setState(() {
                  final newPlaced = _state.placedPieces.where((p) => p != pp).toList();
                  final newAvailable = [..._state.availablePieces, pp.piece];
                  _state = _state.copyWith(placedPieces: newPlaced, availablePieces: newAvailable);
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text('보드의 조각을 탭하면 제거됩니다',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('탭: 회전  |  길게 탭: 반전  |  드래그: 배치',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: _state.availablePieces.map((piece) {
                    final current = _transformedPieces[piece.instanceId] ?? piece;
                    return PieceWidget(
                      key: ValueKey(piece.instanceId),
                      piece: current,
                      cellSize: _cellSize,
                      onTransform: (transformed) {
                        setState(() => _transformedPieces[piece.instanceId] = transformed);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
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
            success ? '🎉 완성!' : '⏰ 시간 초과!',
            style: const TextStyle(
                color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            success
                ? (hasNext ? '3초 후 다음 퍼즐로 이동합니다...' : '모든 퍼즐 완료!')
                : '다음엔 더 빠르게!',
            style: const TextStyle(color: Colors.white70, fontSize: 18),
          ),
          if (success)
            Text(
              '남은 시간: ${_state.remainingSeconds}초',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => setState(_initGame),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('다시 도전'),
              ),
              const SizedBox(width: 12),
              if (success && hasNext)
                ElevatedButton(
                  onPressed: _goNextPuzzle,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: const Text('다음 퍼즐 →'),
                ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                child: const Text('메인으로'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
