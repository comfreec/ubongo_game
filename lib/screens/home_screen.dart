import 'package:flutter/material.dart';
import '../data/puzzles.dart';
import '../models/difficulty.dart';
import '../models/puzzle.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Puzzle> _puzzles;

  @override
  void initState() {
    super.initState();
    _puzzles = getShuffledPuzzles();
  }

  void _reshuffle() {
    setState(() => _puzzles = getShuffledPuzzles());
  }

  void _startGame(int index) {
    final puzzle = _puzzles[index];
    final difficulty = puzzle.pieceIds.length <= 3
        ? Difficulty.easy
        : puzzle.pieceIds.length == 4
            ? Difficulty.normal
            : Difficulty.hard;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          puzzles: _puzzles,
          initialIndex: index,
          difficulty: difficulty,
        ),
      ),
    );
  }
