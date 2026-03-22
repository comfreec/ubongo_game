import '../models/piece.dart';
import '../models/puzzle.dart';
import 'puzzles.dart';

/// 해답의 배치 정보 (조각 instanceId → (row, col, 변형된 cells))
class SolvedPlacement {
  final String instanceId;
  final int row;
  final int col;
  final List<({int row, int col})> cells; // 변형된 셀 좌표
  SolvedPlacement({required this.instanceId, required this.row, required this.col, required this.cells});
}

/// 백트래킹으로 퍼즐 해답을 찾아 배치 정보 반환 (없으면 null)
List<SolvedPlacement>? findSolution(Puzzle puzzle, List<Piece> pieces) {
  final board = List.generate(
    puzzle.rows,
    (r) => List.generate(puzzle.cols, (c) => puzzle.grid[r][c] ? 0 : -1),
  );
  final result = <SolvedPlacement>[];
  if (_solveWithResult(board, pieces, 0, puzzle.rows, puzzle.cols, result)) {
    return result;
  }
  return null;
}

bool _solveWithResult(List<List<int>> board, List<Piece> remaining, int depth,
    int rows, int cols, List<SolvedPlacement> result) {
  if (remaining.isEmpty) {
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++)
        if (board[r][c] == 0) return false;
    return true;
  }
  int firstRow = -1, firstCol = -1;
  outer:
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (board[r][c] == 0) { firstRow = r; firstCol = c; break outer; }
    }
  }
  if (firstRow == -1) return false;

  for (int i = 0; i < remaining.length; i++) {
    final piece = remaining[i];
    for (final variant in _allVariants(piece)) {
      for (final anchor in variant.cells) {
        final pr = firstRow - anchor.row;
        final pc = firstCol - anchor.col;
        if (_canPlace(board, variant, pr, pc, rows, cols)) {
          _place(board, variant, pr, pc, depth + 1);
          result.add(SolvedPlacement(
            instanceId: piece.instanceId,
            row: pr, col: pc,
            cells: variant.cells,
          ));
          final next = [...remaining]..removeAt(i);
          if (_solveWithResult(board, next, depth + 1, rows, cols, result)) return true;
          result.removeLast();
          _unplace(board, variant, pr, pc);
        }
      }
    }
  }
  return false;
}

/// 백트래킹으로 퍼즐 해답 존재 여부 확인
bool hasSolution(Puzzle puzzle, List<String> pieceIds) {
  final pieces = pieceIds.map((id) => allPieces[id]!).toList();
  final board = List.generate(
    puzzle.rows,
    (r) => List.generate(puzzle.cols, (c) => puzzle.grid[r][c] ? 0 : -1),
  );
  return _solve(board, pieces, 0, puzzle.rows, puzzle.cols);
}

bool _solve(List<List<int>> board, List<Piece> remaining, int depth, int rows, int cols) {
  if (remaining.isEmpty) {
    // 모든 칸이 채워졌는지 확인
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c] == 0) return false;
      }
    }
    return true;
  }

  // 첫 번째 빈 칸 찾기
  int firstRow = -1, firstCol = -1;
  outer:
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      if (board[r][c] == 0) {
        firstRow = r;
        firstCol = c;
        break outer;
      }
    }
  }
  if (firstRow == -1) return false;

  // 각 조각을 모든 회전/반전으로 시도
  for (int i = 0; i < remaining.length; i++) {
    final piece = remaining[i];
    final variants = _allVariants(piece);

    for (final variant in variants) {
      // 이 variant의 각 셀을 firstRow,firstCol에 맞춰보기
      for (final anchor in variant.cells) {
        final placeRow = firstRow - anchor.row;
        final placeCol = firstCol - anchor.col;

        if (_canPlace(board, variant, placeRow, placeCol, rows, cols)) {
          _place(board, variant, placeRow, placeCol, depth + 1);
          final newRemaining = [...remaining]..removeAt(i);
          if (_solve(board, newRemaining, depth + 1, rows, cols)) return true;
          _unplace(board, variant, placeRow, placeCol);
        }
      }
    }
  }
  return false;
}

bool _canPlace(List<List<int>> board, Piece piece, int row, int col, int rows, int cols) {
  for (final c in piece.cells) {
    final r = row + c.row;
    final cc = col + c.col;
    if (r < 0 || r >= rows || cc < 0 || cc >= cols) return false;
    if (board[r][cc] != 0) return false;
  }
  return true;
}

void _place(List<List<int>> board, Piece piece, int row, int col, int val) {
  for (final c in piece.cells) {
    board[row + c.row][col + c.col] = val;
  }
}

void _unplace(List<List<int>> board, Piece piece, int row, int col) {
  for (final c in piece.cells) {
    board[row + c.row][col + c.col] = 0;
  }
}

/// 조각의 모든 회전+반전 변형 (중복 제거)
List<Piece> _allVariants(Piece piece) {
  final seen = <String>{};
  final result = <Piece>[];

  Piece current = piece;
  for (int flip = 0; flip < 2; flip++) {
    for (int rot = 0; rot < 4; rot++) {
      final key = current.cells.map((c) => '${c.row},${c.col}').join('|');
      if (seen.add(key)) result.add(current);
      current = current.rotate();
    }
    current = current.flip();
  }
  return result;
}
