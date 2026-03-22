// Flutter 의존성 없는 순수 Dart 퍼즐 검증 스크립트
import 'dart:io';

// ── 셀 타입 ──
typedef Cell = ({int row, int col});

// ── Piece ──
class Piece {
  final String id;
  final List<Cell> cells;
  Piece(this.id, this.cells);

  List<Cell> get normalized {
    final minR = cells.map((c) => c.row).reduce((a, b) => a < b ? a : b);
    final minC = cells.map((c) => c.col).reduce((a, b) => a < b ? a : b);
    final shifted = cells.map((c) => (row: c.row - minR, col: c.col - minC)).toList();
    shifted.sort((a, b) => a.row != b.row ? a.row - b.row : a.col - b.col);
    return shifted;
  }

  Piece rotate() {
    final rotated = cells.map((c) => (row: c.col, col: -c.row)).toList();
    final minR = rotated.map((c) => c.row).reduce((a, b) => a < b ? a : b);
    final minC = rotated.map((c) => c.col).reduce((a, b) => a < b ? a : b);
    return Piece(id, rotated.map((c) => (row: c.row - minR, col: c.col - minC)).toList());
  }

  Piece flip() {
    final flipped = cells.map((c) => (row: c.row, col: -c.col)).toList();
    final minC = flipped.map((c) => c.col).reduce((a, b) => a < b ? a : b);
    return Piece(id, flipped.map((c) => (row: c.row, col: c.col - minC)).toList());
  }

  List<Piece> allVariants() {
    final seen = <String>{};
    final result = <Piece>[];
    Piece cur = this;
    for (int f = 0; f < 2; f++) {
      for (int r = 0; r < 4; r++) {
        final key = cur.normalized.map((c) => '${c.row},${c.col}').join('|');
        if (seen.add(key)) result.add(Piece(id, cur.normalized));
        cur = cur.rotate();
      }
      cur = cur.flip();
    }
    return result;
  }
}

// ── 퍼즐 정의 ──
class Puzzle {
  final String id;
  final int rows, cols;
  final List<List<bool>> grid; // true = 채워야 할 칸
  final List<String> pieceIds;
  Puzzle(this.id, this.rows, this.cols, this.grid, this.pieceIds);
}

Puzzle fromPattern(String id, List<String> pattern, List<String> pieceIds) {
  final rows = pattern.length;
  final cols = pattern.map((r) => r.length).reduce((a, b) => a > b ? a : b);
  final grid = List.generate(rows, (r) =>
    List.generate(cols, (c) => c < pattern[r].length && pattern[r][c] == '#'));
  return Puzzle(id, rows, cols, grid, pieceIds);
}

// ── 조각 데이터 ──
final Map<String, Piece> allPieces = {
  'I2': Piece('I2', [(row:0,col:0),(row:1,col:0)]),
  'I3': Piece('I3', [(row:0,col:0),(row:1,col:0),(row:2,col:0)]),
  'L3': Piece('L3', [(row:0,col:0),(row:1,col:0),(row:1,col:1)]),
  'I4': Piece('I4', [(row:0,col:0),(row:1,col:0),(row:2,col:0),(row:3,col:0)]),
  'O4': Piece('O4', [(row:0,col:0),(row:0,col:1),(row:1,col:0),(row:1,col:1)]),
  'T4': Piece('T4', [(row:0,col:0),(row:0,col:1),(row:0,col:2),(row:1,col:1)]),
  'L4': Piece('L4', [(row:0,col:0),(row:1,col:0),(row:2,col:0),(row:2,col:1)]),
  'S4': Piece('S4', [(row:0,col:1),(row:0,col:2),(row:1,col:0),(row:1,col:1)]),
  'Z4': Piece('Z4', [(row:0,col:0),(row:0,col:1),(row:1,col:1),(row:1,col:2)]),
  'L5': Piece('L5', [(row:0,col:0),(row:1,col:0),(row:2,col:0),(row:3,col:0),(row:3,col:1)]),
  'T5': Piece('T5', [(row:0,col:0),(row:0,col:1),(row:0,col:2),(row:1,col:1),(row:2,col:1)]),
  'P5': Piece('P5', [(row:0,col:0),(row:0,col:1),(row:1,col:0),(row:1,col:1),(row:2,col:0)]),
};

// ── 백트래킹 솔버 ──
bool solve(List<List<int>> board, List<Piece> remaining, int rows, int cols) {
  if (remaining.isEmpty) {
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++)
        if (board[r][c] == 0) return false;
    return true;
  }
  int fr = -1, fc = -1;
  outer: for (int r = 0; r < rows; r++)
    for (int c = 0; c < cols; c++)
      if (board[r][c] == 0) { fr = r; fc = c; break outer; }
  if (fr == -1) return false;

  for (int i = 0; i < remaining.length; i++) {
    for (final v in remaining[i].allVariants()) {
      for (final anchor in v.cells) {
        final pr = fr - anchor.row;
        final pc = fc - anchor.col;
        if (_canPlace(board, v, pr, pc, rows, cols)) {
          _place(board, v, pr, pc, i + 2);
          final next = [...remaining]..removeAt(i);
          if (solve(board, next, rows, cols)) return true;
          _place(board, v, pr, pc, 0);
        }
      }
    }
  }
  return false;
}

bool _canPlace(List<List<int>> board, Piece p, int row, int col, int rows, int cols) {
  for (final c in p.cells) {
    final r2 = row + c.row; final c2 = col + c.col;
    if (r2 < 0 || r2 >= rows || c2 < 0 || c2 >= cols) return false;
    if (board[r2][c2] != 0) return false;
  }
  return true;
}

void _place(List<List<int>> board, Piece p, int row, int col, int val) {
  for (final c in p.cells) board[row + c.row][col + c.col] = val;
}

bool hasSolution(Puzzle puzzle) {
  final pieces = puzzle.pieceIds.map((id) => allPieces[id]!).toList();
  final board = List.generate(puzzle.rows,
    (r) => List.generate(puzzle.cols, (c) => puzzle.grid[r][c] ? 0 : -1));
  return solve(board, pieces, puzzle.rows, puzzle.cols);
}
