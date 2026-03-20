import 'piece.dart';
import 'puzzle.dart';

enum GameStatus { idle, playing, success, failed }

class PlacedPiece {
  final Piece piece;
  final int row;
  final int col;

  const PlacedPiece({required this.piece, required this.row, required this.col});

  List<({int row, int col})> get occupiedCells =>
      piece.cells.map((c) => (row: row + c.row, col: col + c.col)).toList();
}

class GameState {
  final Puzzle puzzle;
  final List<Piece> availablePieces; // 아직 배치 안 된 조각들
  final List<PlacedPiece> placedPieces;
  final GameStatus status;
  final int remainingSeconds;

  const GameState({
    required this.puzzle,
    required this.availablePieces,
    required this.placedPieces,
    required this.status,
    required this.remainingSeconds,
  });

  GameState copyWith({
    List<Piece>? availablePieces,
    List<PlacedPiece>? placedPieces,
    GameStatus? status,
    int? remainingSeconds,
  }) {
    return GameState(
      puzzle: puzzle,
      availablePieces: availablePieces ?? this.availablePieces,
      placedPieces: placedPieces ?? this.placedPieces,
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }

  /// 모든 조각이 배치되어 보드가 완성됐는지 확인
  bool get isSolved {
    if (availablePieces.isNotEmpty) return false;
    final filled = <String>{};
    for (final pp in placedPieces) {
      for (final c in pp.occupiedCells) {
        filled.add('${c.row},${c.col}');
      }
    }
    for (int r = 0; r < puzzle.rows; r++) {
      for (int c = 0; c < puzzle.cols; c++) {
        if (puzzle.grid[r][c] && !filled.contains('$r,$c')) return false;
      }
    }
    return true;
  }
}
