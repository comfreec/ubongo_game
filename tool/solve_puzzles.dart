// 퍼즐 해답 검증 + _make 방식으로 보드 생성
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

// 조각 배치 정보로 보드 생성 (해답 보장)
// rot: 0=원본, 1=90°CW, 2=180°, 3=270°CW, +4=flip 후 rot
List<String> make(List<(String, int, int, int)> placements) {
  final cells = <({int row, int col})>{};
  for (final (id, row, col, rot) in placements) {
    var p = pieces[id]!;
    final flips = rot ~/ 4;
    final rots = rot % 4;
    for (int i = 0; i < flips; i++) p = p.flip();
    for (int i = 0; i < rots; i++) p = p.rotate();
    for (final c in p.cells) {
      cells.add((row: row + c.row, col: col + c.col));
    }
  }
  final maxR = cells.map((c) => c.row).reduce((a,b) => a>b?a:b);
  final maxC = cells.map((c) => c.col).reduce((a,b) => a>b?a:b);
  return List.generate(maxR+1, (r) =>
    List.generate(maxC+1, (c) => cells.contains((row:r,col:c)) ? '#' : '.').join());
}

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

void printBoard(List<String> pattern) {
  for (final row in pattern) print('  $row');
}

void main() {
  // _make로 해답 보장 퍼즐 생성
  // rot: 0=원본, 1=90°CW, 2=180°, 3=270°CW, 4=flip, 5=flip+90°CW, 6=flip+180°, 7=flip+270°CW

  // ── 쉬움 (3조각) ──────────────────────────────────────────

  // p01: T4 + L3 + I2 = 9칸
  // T4 원본(row0,col0): ###  .#.
  // L3 원본(row2,col1): #.   ##
  // I2 세로(row4,col2): #    #
  final p01 = make([('T4',0,0,0), ('L3',2,1,0), ('I2',4,2,0)]);

  // p04: T4 + I3 + I2 = 9칸
  // T4 rot1(row0,col0): #.  ##  .#
  //                     ##      #
  //                     #
  // T4 rot1: col방향 T → 세로 T
  // T4 rot1 cells: (0,0)(1,0)(2,0)(1,1) → 세로 막대 + 오른쪽 돌기
  // I3 세로(row0,col2)
  // I2 세로(row3,col1)
  final p04 = make([('T4',0,0,1), ('I3',0,2,0), ('I2',3,1,0)]);

  // p06: T4 + L4 + L3 + I2 = 13칸
  // T4 원본(row0,col0): (0,0)(0,1)(0,2)(1,1) → 3칸 row0 + 1칸 row1
  // L4 rot3(row2,col0): L4 rot3 = (0,1)(1,1)(2,0)(2,1) → 역L 가로
  // L3 원본(row4,col0): (0,0)(1,0)(1,1)
  // I2 세로(row5,col2)
  final p06 = make([('T4',0,0,0), ('L4',2,0,3), ('L3',4,0,0), ('I2',5,2,0)]);

  // p09: L4 + Z4 + T4 + I2 = 14칸
  // L4 원본(row0,col0)
  // Z4 원본(row0,col2)
  // T4 rot2(row2,col1): .#.  → 180° T
  //                     ###
  // I2 가로(row4,col1): ##
  final p09 = make([('L4',0,0,0), ('Z4',0,2,0), ('T4',2,1,2), ('I2',4,1,4)]);

  // p10: P5 + T4 + L3 + I2 = 14칸
  // P5 원본(row0,col0): ##
  //                     ##
  //                     #.
  // T4 rot3(row0,col2): .#  → 270° T
  //                     ##
  //                     .#
  // L3 rot2(row3,col2): ##  → 180° L3
  //                     #.
  // I2 세로(row5,col3)
  final p10 = make([('P5',0,0,0), ('T4',0,2,3), ('L3',3,2,2), ('I2',5,3,0)]);

  // p12: T5 + L4 + Z4 + I2 = 15칸
  // T5 원본(row0,col0): ###
  //                     .#.
  //                     .#.
  // L4 rot1(row0,col3): ###  → L4 rot1: 가로 L
  //                     #..
  // Z4 원본(row2,col2): ##
  //                     .##  → 실제 Z4: (0,0)(0,1)(1,1)(1,2)
  // I2 세로(row4,col3)
  final p12 = make([('T5',0,0,0), ('L4',0,3,1), ('Z4',2,2,0), ('I2',4,3,0)]);

  final puzzles = [
    ('p01', p01, ['T4','L3','I2']),
    ('p02', ['.##','##.','#..','##.','##.'], ['S4','L3','I2']),
    ('p03', ['#..','#..','##.','.#.','.#.','.##','..#'], ['L4','L3','I2']),
    ('p04', p04, ['T4','I3','I2']),
    ('p05', ['#..','#..','##.','.##','..#','..#','.##'], ['L4','S4','I2']),
    ('p06', p06, ['T4','L4','L3','I2']),
    ('p07', ['###.','.#..','.##.','##..','#...','##..','.##.','..#.'], ['T4','L4','S4','I2']),
    ('p08', ['##..','##..','.##.','##..','#...','##..','.##.'], ['O4','S4','L3','I2']),
    ('p09', p09, ['L4','Z4','T4','I2']),
    ('p10', p10, ['P5','T4','L3','I2']),
    ('p11', ['#...','#...','#...','##..','.##.','..##','...#','..##','.##.'], ['L5','S4','L3','I2']),
    ('p12', p12, ['T5','L4','Z4','I2']),
  ];

  bool allOk = true;
  for (final (id, pattern, pids) in puzzles) {
    final boardCells = pattern.fold(0, (s,r) => s + r.split('').where((c)=>c=='#').length);
    final pieceCells = pids.fold(0, (s,p) => s + (pieces[p]?.cells.length ?? 0));
    final ok = hasSolution(pattern, pids);
    if (!ok) allOk = false;
    final sizeOk = boardCells == pieceCells ? '' : ' [칸수불일치: board=$boardCells pieces=$pieceCells]';
    print('${ok ? "✓" : "✗"} $id: ${pids.join("+")}$sizeOk');
    if (ok) printBoard(pattern);
  }
  print(allOk ? '\n모두 해답 있음!' : '\n❌ 해답 없는 퍼즐 있음');
}
