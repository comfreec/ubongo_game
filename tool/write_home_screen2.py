# -*- coding: utf-8 -*-
code = r"""import 'package:flutter/material.dart';
import '../data/puzzles.dart';
import '../models/puzzle.dart';
import '../services/score_service.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Puzzle> _puzzles;
  Set<String> _completed = {};
  Map<String, int> _bestScores = {};
  // 0=전체, 3=쉬움(3조각), 4=보통(4조각)
  int _filterPieces = 0;

  @override
  void initState() {
    super.initState();
    _puzzles = getShuffledPuzzles();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final completed = await ScoreService.getCompleted();
    final scores = <String, int>{};
    for (final p in _puzzles) {
      final best = await ScoreService.getBest(p.id);
      if (best != null) scores[p.id] = best;
    }
    if (mounted) setState(() {
      _completed = completed;
      _bestScores = scores;
    });
  }

  void _reshuffle() {
    setState(() => _puzzles = getShuffledPuzzles());
  }

  List<Puzzle> get _filtered {
    if (_filterPieces == 0) return _puzzles;
    return _puzzles.where((p) => p.pieceIds.length == _filterPieces).toList();
  }

  void _startGame(int indexInFiltered, {bool practice = false}) {
    final filtered = _filtered;
    final puzzle = filtered[indexInFiltered];
    // 전체 리스트에서 해당 퍼즐의 인덱스 찾기
    final globalIndex = _puzzles.indexWhere((p) => p.id == puzzle.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          puzzles: _puzzles,
          initialIndex: globalIndex,
          practiceMode: practice,
        ),
      ),
    ).then((_) => _loadScores());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final completedCount = _completed.length;
    final totalCount = _puzzles.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text(
              '\uBE14\uB85D\uD53C\uD2B8',
              style: TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '\uC870\uAC01\uC744 \uB9DE\uCDB0 \uBCF4\uB4DC\uB97C \uCC44\uC6B0\uC138\uC694!',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // 진행률 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$completedCount / $totalCount \uD37C\uC990 \uC644\uB8CC',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('${totalCount > 0 ? (completedCount * 100 ~/ totalCount) : 0}%',
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalCount > 0 ? completedCount / totalCount : 0,
                      backgroundColor: Colors.white12,
                      color: Colors.blueAccent,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 필터 + 셔플
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(label: '\uC804\uCCB4', selected: _filterPieces == 0,
                      onTap: () => setState(() => _filterPieces = 0)),
                  const SizedBox(width: 8),
                  _FilterChip(label: '\uC27D\uC74C(3)', selected: _filterPieces == 3,
                      onTap: () => setState(() => _filterPieces = 3)),
                  const SizedBox(width: 8),
                  _FilterChip(label: '\uBCF4\uD1B5(4)', selected: _filterPieces == 4,
                      onTap: () => setState(() => _filterPieces = 4)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _reshuffle,
                    icon: const Icon(Icons.shuffle, size: 16, color: Colors.blueAccent),
                    label: const Text('\uC12D\uAE30',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final puzzle = filtered[i];
                  final isCompleted = _completed.contains(puzzle.id);
                  final best = _bestScores[puzzle.id];
                  final isEasy = puzzle.pieceIds.length <= 3;
                  return _PuzzleCard(
                    index: i + 1,
                    puzzle: puzzle,
                    isEasy: isEasy,
                    isCompleted: isCompleted,
                    bestSeconds: best,
                    onTap: () => _startGame(i),
                    onPractice: () => _startGame(i, practice: true),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _PuzzleCard extends StatelessWidget {
  final int index;
  final Puzzle puzzle;
  final bool isEasy;
  final bool isCompleted;
  final int? bestSeconds;
  final VoidCallback onTap;
  final VoidCallback onPractice;

  const _PuzzleCard({
    required this.index,
    required this.puzzle,
    required this.isEasy,
    required this.isCompleted,
    required this.bestSeconds,
    required this.onTap,
    required this.onPractice,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = isEasy ? Colors.greenAccent : Colors.orangeAccent;
    final diffLabel = isEasy ? '\uC27D\uC74C' : '\uBCF4\uD1B5';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          // 번호 + 완료 표시
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 56,
              height: 72,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.blueAccent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCompleted)
                    const Icon(Icons.check_circle, color: Colors.blueAccent, size: 20)
                  else
                    Text('$index',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // 퍼즐 정보
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('\uD37C\uC990 $index',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(diffLabel,
                              style: TextStyle(color: diffColor, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${puzzle.rows}x${puzzle.cols}  \u00B7  \uC870\uAC01 ${puzzle.pieceIds.length}\uAC1C'
                      '${bestSeconds != null ? "  \u00B7  \uBCA0\uC2A4\uD2B8: ${bestSeconds}\uCD08" : ""}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 연습 모드 버튼
          GestureDetector(
            onTap: onPractice,
            child: Container(
              width: 48,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.self_improvement, color: Colors.greenAccent, size: 18),
                  SizedBox(height: 2),
                  Text('\uC5F0\uC2B5', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
"""

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()
print(f"Lines: {len(c.splitlines())}, Braces: {c.count(chr(123))}/{c.count(chr(125))}")
