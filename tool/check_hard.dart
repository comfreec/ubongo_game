// dart run tool/check_hard.dart
import '../lib/data/puzzles.dart';
import '../lib/data/puzzle_solver.dart';
import '../lib/models/puzzle.dart';

Puzzle fromPattern(String id, List<String> pattern, List<String> pieceIds) {
  final rows = pattern.length;
  final cols = pattern.map((r) => r.length).reduce((a, b) => a > b ? a : b);
  final grid = List.generate(rows, (r) =>
    List.generate(cols, (c) => c < pattern[r].length && pattern[r][c] == '#'));
  return Puzzle(id: id, rows: rows, cols: cols, grid: grid, pieceIds: pieceIds);
}

void check(String id, List<String> pattern, List<String> pieces) {
  final p = fromPattern(id, pattern, pieces);
  final cells = pattern.join().replaceAll('.', '').length;
  final pieceCells = pieces.map((id) => allPieces[id]!.cells.length).reduce((a,b)=>a+b);
  if (cells != pieceCells) {
    print('$id: CELL MISMATCH board=$cells pieces=$pieceCells');
    return;
  }
  final ok = hasSolution(p, pieces);
  print('$id [${pieces.join(",")}]: ${ok ? "OK" : "NO SOLUTION"}');
}

void main() {
  // 5조각 어려움 퍼즐 후보들
  // 총 20칸 보드 (4x5 or 5x4)

  // T4+L4+S4+Z4+O4 = 4+4+4+4+4 = 20
  check('h01', ['#####','#####','#####','#####'], ['T4','L4','S4','Z4','O4']);
  check('h02', ['#####','#####','#####','#####'], ['T4','L4','S4','O4','I4']);
  check('h03', ['#####','#####','#####','#####'], ['T4','Z4','L4','I4','O4']);
  check('h04', ['#####','#####','#####','#####'], ['T4','S4','Z4','I4','O4']);

  // 5x4 보드
  check('h05', ['####','####','####','####','####'], ['T4','L4','S4','Z4','O4']);
  check('h06', ['####','####','####','####','####'], ['T4','L4','S4','O4','I4']);
  check('h07', ['####','####','####','####','####'], ['T4','Z4','L4','I4','O4']);
  check('h08', ['####','####','####','####','####'], ['T4','S4','Z4','I4','O4']);

  // 불규칙 보드 (5조각, 20칸)
  // P5+T4+L4+S4+I3 = 5+4+4+4+3 = 20
  check('h09', ['#####','#####','#####','#####'], ['P5','T4','L4','S4','I3']);
  check('h10', ['#####','#####','#####','#####'], ['T5','T4','L4','S4','I3']);
  check('h11', ['#####','#####','#####','#####'], ['L5','T4','L4','S4','I3']);

  // L5+T5+P5+I4+I2 = 5+5+5+4+2 = 21 → 안맞음
  // L5+T5+O4+I3+I2 = 5+5+4+3+2 = 19 → 안맞음
  // L5+T5+O4+L3+I2 = 5+5+4+3+2 = 19 → 안맞음
  // L5+T5+P5+I3+I2 = 5+5+5+3+2 = 20
  check('h12', ['#####','#####','#####','#####'], ['L5','T5','P5','I3','I2']);
  check('h13', ['####','####','####','####','####'], ['L5','T5','P5','I3','I2']);

  // T5+P5+T4+L3+I2 = 5+5+4+3+2 = 19 → 안맞음
  // T5+P5+T4+L4+I2 = 5+5+4+4+2 = 20
  check('h14', ['#####','#####','#####','#####'], ['T5','P5','T4','L4','I2']);
  check('h15', ['####','####','####','####','####'], ['T5','P5','T4','L4','I2']);

  // L5+P5+T4+L4+I2 = 5+5+4+4+2 = 20
  check('h16', ['#####','#####','#####','#####'], ['L5','P5','T4','L4','I2']);
  check('h17', ['####','####','####','####','####'], ['L5','P5','T4','L4','I2']);

  // 불규칙 모양 보드
  // T4+L4+S4+Z4+O4 = 20
  check('h18', ['.####','#####','#####','####.'], ['T4','L4','S4','Z4','O4']);
  check('h19', ['####.','#####','#####','.####'], ['T4','L4','S4','Z4','O4']);
  check('h20', ['#####.','.#####','#####.'], ['T4','L4','S4','Z4','O4']);
  check('h21', ['.#####','#####.','.#####'], ['T4','L4','S4','Z4','O4']);

  // T5+L4+S4+Z4+I3 = 5+4+4+4+3 = 20
  check('h22', ['.####','#####','#####','####.'], ['T5','L4','S4','Z4','I3']);
  check('h23', ['####.','#####','#####','.####'], ['T5','L4','S4','Z4','I3']);
  check('h24', ['.####','#####','#####','####.'], ['P5','L4','S4','Z4','I3']);
  check('h25', ['####.','#####','#####','.####'], ['P5','L4','S4','Z4','I3']);
}
