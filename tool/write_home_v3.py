# -*- coding: utf-8 -*-
content = '''import 'package:flutter/material.dart';
import '../data/puzzles.dart';
import '../models/puzzle.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Puzzle> _allPuzzles;
  int _filterIndex = 0; // 0=전체 1=쉬움 2=보통 3=어려움

  @override
  void initState() {
    super.initState();
    _allPuzzles = getShuffledPuzzles();
  }

  List<Puzzle> get _filtered {
    switch (_filterIndex) {
      case 1: return _allPuzzles.where((p) => p.pieceIds.length <= 3).toList();
      case 2: return _allPuzzles.where((p) => p.pieceIds.length == 4).toList();
      case 3: return _allPuzzles.where((p) => p.pieceIds.length >= 5).toList();
      default: return _allPuzzles;
    }
  }

  void _startGame(Puzzle puzzle) {
    final globalIndex = _allPuzzles.indexOf(puzzle);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          puzzles: _allPuzzles,
          initialIndex: globalIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
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
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '\uC870\uAC01\uC744 \uB9DE\uCDB0 \uBCF4\uB4DC\uB97C \uCC44\uC6B0\uC138\uC694!',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FilterTab(label: '\uC804\uCCB4', selected: _filterIndex == 0,
                    color: Colors.white70, onTap: () => setState(() => _filterIndex = 0)),
                const SizedBox(width: 8),
                _FilterTab(label: '\uC27D\uC74C', selected: _filterIndex == 1,
                    color: Colors.greenAccent, onTap: () => setState(() => _filterIndex = 1)),
                const SizedBox(width: 8),
                _FilterTab(label: '\uBCF4\uD1B5', selected: _filterIndex == 2,
                    color: Colors.orangeAccent, onTap: () => setState(() => _filterIndex = 2)),
                const SizedBox(width: 8),
                _FilterTab(label: '\uC5B4\uB824\uC6C0', selected: _filterIndex == 3,
                    color: Colors.redAccent, onTap: () => setState(() => _filterIndex = 3)),
              ],
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => setState(() => _allPuzzles = getShuffledPuzzles()),
              icon: const Icon(Icons.shuffle, color: Colors.blueAccent, size: 16),
              label: const Text('\uC21C\uC11C \uC12D\uAE30',
                  style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final puzzle = filtered[i];
                  final count = puzzle.pieceIds.length;
                  final isEasy = count <= 3;
                  final isHard = count >= 5;
                  return _PuzzleCard(
                    index: i + 1,
                    puzzle: puzzle,
                    isEasy: isEasy,
                    isHard: isHard,
                    onTap: () => _startGame(puzzle),
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

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white24,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white38,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PuzzleCard extends StatelessWidget {
  final int index;
  final Puzzle puzzle;
  final bool isEasy;
  final bool isHard;
  final VoidCallback onTap;

  const _PuzzleCard({
    required this.index,
    required this.puzzle,
    required this.isEasy,
    required this.isHard,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = isEasy
        ? Colors.greenAccent
        : isHard
            ? Colors.redAccent
            : Colors.orangeAccent;
    final diffLabel = isEasy ? '\uC27D\uC74C' : isHard ? '\uC5B4\uB824\uC6C0' : '\uBCF4\uD1B5';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  \'\$index\',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  \'\uD37C\uC990 \$index\',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      \'\${puzzle.rows}x\${puzzle.cols}  |  \uC870\uAC01 \${puzzle.pieceIds.length}\uAC1C  |  \',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    Text(diffLabel,
                        style: TextStyle(color: diffColor, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}
'''

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
print(f"Written: {len(lines)} lines")
print(f"Has _filterIndex: {'_filterIndex' in open('lib/screens/home_screen.dart', encoding='utf-8').read()}")
