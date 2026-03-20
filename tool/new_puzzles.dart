typedef Cell = ({int row, int col});

class Piece {
  final String id;
  final List<Cell> cells;
  Piece(this.id, this.cells);
  Piece rotate() => _norm(cells.map((c) => (row: c.col, col: -c.row)).toList());
  Piece flip()   => _norm(cells.map((c) => (row: c.row, col: -c.col)).toList());
  Piece _norm(List<Cell> nc) {
    final mr = nc.map((c) => c.row).reduce((a,b) => a<b?a:b);
    final mc = nc.map((c) => c.col).reduce((a,b) => a<b?a:b);
    return Piece(id, nc.map((c) => (row:c.row-mr, col:c.col-mc)).toList());
  }
}

final Map<String, Piece> pieces = {
  'I2': Piece('I2', [(row:0,col:0),(row:1,col:0)]),
  'I3': Piece('I3', [(row:0,col:0),(row:1,col:0),(row:2,col:0)]),
  'L3': Piece('L3', [(row:0,col:0),(row:1,col:0),(row:1,col:1)]),
  'O4': Piece('O4', [(row:0,col:0),(row:0,col:1),(row:1,col:0),(row:1,col:1)]),
  'T4': Piece('T4', [(row:0,col:0),(row:0,col:1),(row:0,col:2),(row:1,col:1)]),
  'L4': Piece('L4', [(row:0,col:0),(row:1,col:0),(row:2,col:0),(row:2,col:1)]),
  'S4': Piece('S4', [(row:0,col:1),(row:0,col:2),(row:1,col:0),(row:1,col:1)]),
  'Z4': Piece('Z4', [(row:0,col:0),(row:0,col:1),(row:1,col:1),(row:1,col:2)]),
  'L5': Piece('L5', [(row:0,col:0),(row:1,col:0),(row:2,col:0),(row:3,col:0),(row:3,col:1)]),
  'T5': Piece('T5', [(row:0,col:0),(row:0,col:1),(row:0,col:2),(row:1,col:1),(row:2,col:1)]),
  'P5': Piece('P5', [(row:0,col:0),(row:0,col:1),(row:1,col:0),(row:1,col:1),(row:2,col:0)]),
  'N4': Piece('N4', [(row:0,col:0),(row:1,col:0),(row:1,col:1),(row:2,col:1)]),
  'J4': Piece('J4', [(row:0,col:1),(row:1,col:1),(row:2,col:0),(row:2,col:1)]),
};

List<List<bool>> parsePattern(List<String> pattern) {
  final rows = pattern.length;
  final cols = pattern.map((r) => r.length).reduce((a,b) => a>b?a:b);
  return List.generate(rows, (r) =>
    List.generate(cols, (c) => c < pattern[r].length && pattern[r][c] == '#'));
}

List<Piece> allVariants(Piece p) {
  final seen = <String>{};
  final result = <Piece>[];
  Piece cur = p;
  for (int f = 0; f < 2; f++) {
    for (int r = 0; r < 4; r++) {
      final key = cur.cells.map((c) => '${c.row},${c.col}').join('|');
      if (seen.add(key)) result.add(cur);
      cur = cur.rotate();
    }
    cur = cur.flip();
  }
  return result;
}

bool solve(List<List<int>> board, List<Piece> rem, int rows, int cols) {
  if (rem.isEmpty) {
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
  for (int i = 0; i < rem.length; i++) {
    for (final v in allVariants(rem[i])) {
      for (final anchor in v.cells) {
        final pr = fr - anchor.row, pc = fc - anchor.col;
        if (_canPlace(board, v, pr, pc, rows, cols)) {
          _place(board, v, pr, pc, i+1);
          final nr = [...rem]..removeAt(i);
          if (solve(board, nr, rows, cols)) return true;
          _unplace(board, v, pr, pc);
        }
      }
    }
  }
  return false;
}

bool _canPlace(List<List<int>> b, Piece p, int row, int col, int rows, int cols) {
  for (final c in p.cells) {
    final r = row+c.row, cc = col+c.col;
    if (r<0||r>=rows||cc<0||cc>=cols) return false;
    if (b[r][cc] != 0) return false;
  }
  return true;
}
void _place(List<List<int>> b, Piece p, int row, int col, int val) {
  for (final c in p.cells) b[row+c.row][col+c.col] = val;
}
void _unplace(List<List<int>> b, Piece p, int row, int col) {
  for (final c in p.cells) b[row+c.row][col+c.col] = 0;
}

bool hasSolution(List<String> pattern, List<String> pieceIds) {
  final grid = parsePattern(pattern);
  final rows = grid.length, cols = grid[0].length;
  final board = List.generate(rows, (r) =>
    List.generate(cols, (c) => grid[r][c] ? 0 : -1));
  final ps = pieceIds.map((id) => pieces[id]!).toList();
  return solve(board, ps, rows, cols);
}

void main() {
  // 새 퍼즐 후보들 검증
  final candidates = [
    // ── 쉬움 (3조각) ──
    // P13: O4+I3+I2 = 9칸
    ('p13', ['O4','I3','I2'], [
      ['##.','###','###'],
      ['###','###','.##'],
      ['###','###','##.'],
      ['.##','###','###'],
      ['##.','####','##.'],
      ['.##','####','.##'],
    ]),
    // P14: L3+I3+I2 = 7칸 — 너무 작으니 L4+I3+I2=9칸
    ('p14', ['L4','I3','I2'], [
      ['##.','###','###'],
      ['###','###','.##'],
      ['###','###','##.'],
      ['.##','###','###'],
      ['##..','####','###.'],
      ['..##','####','.###'],
      ['###.','####','..##'],
      ['.###','####','##..'],
    ]),
    // P15: S4+I3+I2 = 9칸
    ('p15', ['S4','I3','I2'], [
      ['##.','###','###'],
      ['###','###','.##'],
      ['.##','###','###'],
      ['###','###','##.'],
      ['##..','####','###.'],
      ['..##','####','.###'],
      ['.###','####','##..'],
      ['###.','####','..##'],
    ]),
    // P16: Z4+I3+I2 = 9칸
    ('p16', ['Z4','I3','I2'], [
      ['##.','###','###'],
      ['###','###','.##'],
      ['.##','###','###'],
      ['###','###','##.'],
      ['##..','####','###.'],
      ['..##','####','.###'],
      ['.###','####','##..'],
      ['###.','####','..##'],
    ]),
    // P17: T4+O4+I2 = 10칸
    ('p17', ['T4','O4','I2'], [
      ['##..','#####','..##'],
      ['..##','#####','##..'],
      ['.###','#####','##..'],
      ['##..','#####','.###'],
      ['###.','#####','..##'],
      ['..##','#####','###.'],
    ]),
    // P18: L4+O4+I2 = 10칸
    ('p18', ['L4','O4','I2'], [
      ['##..','#####','..##'],
      ['..##','#####','##..'],
      ['.###','#####','##..'],
      ['##..','#####','.###'],
      ['###.','#####','..##'],
      ['..##','#####','###.'],
    ]),

    // ── 보통 (4조각) ──
    // P19: O4+L4+L3+I2 = 13칸
    ('p19', ['O4','L4','L3','I2'], [
      ['.###.','#####','#####'],
      ['#####','#####','.###.'],
      ['####.','#####','####.'],
      ['.####','#####','.####'],
      ['####.','#####','.####'],
      ['.####','#####','####.'],
      ['###..','#####','#####'],
      ['..###','#####','#####'],
      ['#####','#####','###..'],
      ['#####','#####','..###'],
    ]),
    // P20: O4+T4+L3+I2 = 13칸
    ('p20', ['O4','T4','L3','I2'], [
      ['.###.','#####','#####'],
      ['#####','#####','.###.'],
      ['####.','#####','####.'],
      ['.####','#####','.####'],
      ['####.','#####','.####'],
      ['.####','#####','####.'],
      ['###..','#####','#####'],
      ['..###','#####','#####'],
    ]),
    // P21: S4+Z4+L3+I2 = 13칸
    ('p21', ['S4','Z4','L3','I2'], [
      ['.###.','#####','#####'],
      ['#####','#####','.###.'],
      ['####.','#####','####.'],
      ['.####','#####','.####'],
      ['####.','#####','.####'],
      ['.####','#####','####.'],
      ['###..','#####','#####'],
      ['..###','#####','#####'],
    ]),
    // P22: T5+S4+L3+I2 = 14칸
    ('p22', ['T5','S4','L3','I2'], [
      ['#####','#####','####.'],
      ['#####','#####','.####'],
      ['####.','#####','#####'],
      ['.####','#####','#####'],
      ['#####','.####','#####'],
      ['#####','####.','#####'],
      ['.###.','#####','#####','#....'],
      ['....#','#####','#####','.###.'],
    ]),
    // P23: P5+L4+L3+I2 = 14칸
    ('p23', ['P5','L4','L3','I2'], [
      ['#####','#####','####.'],
      ['#####','#####','.####'],
      ['####.','#####','#####'],
      ['.####','#####','#####'],
      ['#####','.####','#####'],
      ['#####','####.','#####'],
      ['.###.','#####','#####','#....'],
      ['....#','#####','#####','.###.'],
    ]),
    // P24: L5+T4+L3+I2 = 14칸
    ('p24', ['L5','T4','L3','I2'], [
      ['#####','#####','####.'],
      ['#####','#####','.####'],
      ['####.','#####','#####'],
      ['.####','#####','#####'],
      ['#####','.####','#####'],
      ['#####','####.','#####'],
      ['.###.','#####','#####','#....'],
      ['....#','#####','#####','.###.'],
    ]),
    // P25: T5+O4+L3+I2 = 14칸
    ('p25', ['T5','O4','L3','I2'], [
      ['#####','#####','####.'],
      ['#####','#####','.####'],
      ['####.','#####','#####'],
      ['.####','#####','#####'],
      ['#####','.####','#####'],
      ['#####','####.','#####'],
    ]),
    // P26: P5+S4+L3+I2 = 14칸
    ('p26', ['P5','S4','L3','I2'], [
      ['#####','#####','####.'],
      ['#####','#####','.####'],
      ['####.','#####','#####'],
      ['.####','#####','#####'],
      ['#####','.####','#####'],
      ['#####','####.','#####'],
    ]),
    // P27: L5+L4+L3+I2 = 14칸
    ('p27', ['L5','L4','L3','I2'], [
      ['#####','#####','####.'],
      ['#####','#####','.####'],
      ['####.','#####','#####'],
      ['.####','#####','#####'],
      ['#####','.####','#####'],
      ['#####','####.','#####'],
    ]),
    // P28: T5+Z4+L3+I2 = 14칸
    ('p28', ['T5','Z4','L3','I2'], [
      ['#####','#####','####.'],
      ['#####','#####','.####'],
      ['####.','#####','#####'],
      ['.####','#####','#####'],
      ['#####','.####','#####'],
      ['#####','####.','#####'],
    ]),
  ];

  print('=== 새 퍼즐 검증 ===\n');
  int found = 0;
  for (final (id, pids, patterns) in candidates) {
    bool ok = false;
    for (final pattern in patterns) {
      if (hasSolution(pattern, pids)) {
        print('✓ $id [${pids.join("+")}]');
        for (final r in pattern) print('  $r');
        print('');
        ok = true;
        found++;
        break;
      }
    }
    if (!ok) print('✗ $id [${pids.join("+")}] — 해답 없음\n');
  }
  print('발견: $found/${candidates.length}');
}
