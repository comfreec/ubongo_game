// 조각 모양 시각화 + 새 퍼즐 설계
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
  String show() {
    final mr = cells.map((c) => c.row).reduce((a,b) => a>b?a:b);
    final mc = cells.map((c) => c.col).reduce((a,b) => a>b?a:b);
    final grid = List.generate(mr+1, (r) => List.generate(mc+1, (c) => '.'));
    for (final c in cells) grid[c.row][c.col] = '#';
    return grid.map((r) => r.join()).join('\n');
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
};

void showPiece(String id) {
  final p = pieces[id]!;
  print('── $id ──');
  for (int rot = 0; rot < 4; rot++) {
    var cur = p;
    for (int i = 0; i < rot; i++) cur = cur.rotate();
    print('rot$rot:');
    print(cur.show().split('\n').map((r) => '  $r').join('\n'));
  }
  print('');
}

// 조각을 특정 위치에 배치했을 때 차지하는 셀 반환
Set<({int row, int col})> place(String id, int row, int col, int rot) {
  var p = pieces[id]!;
  if (rot >= 4) p = p.flip();
  for (int i = 0; i < rot % 4; i++) p = p.rotate();
  return {for (final c in p.cells) (row: row + c.row, col: col + c.col)};
}

// 여러 배치를 합쳐서 보드 출력
void showBoard(String name, List<(String, int, int, int)> placements) {
  final all = <({int row, int col}), String>{};
  bool overlap = false;
  for (final (id, row, col, rot) in placements) {
    final cells = place(id, row, col, rot);
    for (final c in cells) {
      if (all.containsKey(c)) { overlap = true; print('  ⚠ 겹침: $id at (${c.row},${c.col}) with ${all[c]}'); }
      all[c] = id;
    }
  }
  if (overlap) { print('$name: 겹침 있음!\n'); return; }
  final maxR = all.keys.map((c) => c.row).reduce((a,b) => a>b?a:b);
  final maxC = all.keys.map((c) => c.col).reduce((a,b) => a>b?a:b);
  final grid = List.generate(maxR+1, (r) => List.generate(maxC+1, (c) => '.'));
  for (final e in all.entries) grid[e.key.row][e.key.col] = '#';
  final pattern = grid.map((r) => r.join()).toList();
  final cnt = all.length;
  print('$name ($cnt칸):');
  for (final r in pattern) print('  $r');
  print('');
}

void main() {
  // 조각 모양 확인
  for (final id in ['T4','L4','S4','Z4','L3','I3','I2','O4','P5','T5','L5']) {
    showPiece(id);
  }

  print('\n\n=== 새 퍼즐 설계 ===\n');

  // ── 쉬움 3조각 ──────────────────────────────────────────
  // 목표: 2D로 넓게 퍼진 불규칙 모양 (세로로 길지 않게)

  // p01: T4(4)+L3(3)+I2(2)=9
  // T4 원본: ###  (row0,col0~2) + (row1,col1)
  //          .#.
  // L3 rot1: ##   (row0,col0~1) + (row1,col0)
  //          #
  // I2 가로: ##   (row0,col0~1)
  //
  // 배치: T4 row0,col0 / L3 rot1 row2,col0 / I2 가로 row1,col2
  // T4: (0,0)(0,1)(0,2)(1,1)
  // L3 rot1: (0,0)(0,1)(1,0) → placed at (2,0): (2,0)(2,1)(3,0)
  // I2 rot1: (0,0)(0,1) → placed at (1,2): (1,2)(1,3)
  // 겹침 없음, 연결 확인: (1,1)-(2,1) 연결됨
  showBoard('p01_v1 T4+L3+I2', [('T4',0,0,0), ('L3',2,0,1), ('I2',1,2,1)]);

  // p01_v2: T4 rot1 + L3 + I2
  // T4 rot1: #.  (0,0)(1,0)(2,0)(1,1)
  //          ##
  //          #
  // L3 rot2: ##  (0,0)(0,1)(1,1) → placed at (0,2): (0,2)(0,3)(1,3)
  // I2 가로: placed at (2,1): (2,1)(2,2)
  showBoard('p01_v2 T4+L3+I2', [('T4',0,0,1), ('L3',0,2,2), ('I2',2,1,1)]);

  // p02: S4(4)+L3(3)+I2(2)=9
  // S4 원본: .##  (0,1)(0,2)(1,0)(1,1)
  //          ##.
  // L3 rot3: .#  (0,1)(1,0)(1,1) → placed at (2,0): (2,1)(3,0)(3,1)
  // I2 가로: placed at (0,3): (0,3)(0,4) → 연결 안됨
  // I2 세로: placed at (2,2): (2,2)(3,2)
  showBoard('p02_v1 S4+L3+I2', [('S4',0,0,0), ('L3',2,0,3), ('I2',2,2,0)]);

  // p02_v2: S4 rot1 + L3 + I2
  // S4 rot1: #.  (0,0)(1,0)(1,1)(2,1)
  //          ##
  //          .#
  // L3 rot1: ##  placed at (0,1): (0,1)(0,2)(1,1) → 겹침 (1,1)
  // L3 원본: placed at (0,2): (0,2)(1,2)(1,3)
  // I2 가로: placed at (2,2): (2,2)(2,3)
  showBoard('p02_v2 S4+L3+I2', [('S4',0,0,1), ('L3',0,2,0), ('I2',2,2,1)]);

  // p03: L4(4)+L3(3)+I2(2)=9
  // L4 rot1: ###  (0,0)(0,1)(0,2)(1,0)
  //          #..
  // L3 rot2: ##  (0,0)(0,1)(1,1) → placed at (1,1): (1,1)(1,2)(2,2)
  // I2 세로: placed at (1,3): (1,3)(2,3)
  showBoard('p03_v1 L4+L3+I2', [('L4',0,0,1), ('L3',1,1,2), ('I2',1,3,0)]);

  // p04: T4(4)+I3(3)+I2(2)=9
  // T4 원본: ###  placed at (0,0)
  //          .#.
  // I3 가로: ###  placed at (1,0): (1,0)(1,1)(1,2) → 겹침 (1,1)
  // I3 가로: placed at (2,0): (2,0)(2,1)(2,2)
  // I2 가로: placed at (1,0): (1,0)(1,1) → 겹침
  // I2 세로: placed at (0,3): (0,3)(1,3)
  showBoard('p04_v1 T4+I3+I2', [('T4',0,0,0), ('I3',2,0,1), ('I2',0,3,0)]);

  // p05: L4(4)+S4(4)+I2(2)=10
  // L4 원본: #.  placed at (0,0): (0,0)(1,0)(2,0)(2,1)
  //          #.
  //          ##
  // S4 원본: .##  placed at (0,1): (0,2)(0,3)(1,1)(1,2)
  //          ##.
  // I2 가로: placed at (2,2): (2,2)(2,3)
  showBoard('p05_v1 L4+S4+I2', [('L4',0,0,0), ('S4',0,1,0), ('I2',2,2,1)]);

  // ── 보통 4조각 ──────────────────────────────────────────

  // p06: T4(4)+L4(4)+L3(3)+I2(2)=13
  // T4 원본 (0,0): (0,0)(0,1)(0,2)(1,1)
  // L4 rot3 (0,3): L4 rot3 = (0,1)(1,0)(1,1)(2,1) → (0,4)(1,3)(1,4)(2,4)
  // L3 rot2 (2,0): L3 rot2 = (0,0)(0,1)(1,1) → (2,0)(2,1)(3,1)
  // I2 가로 (1,2): (1,2)(1,3) → 겹침 (1,3)
  // I2 세로 (2,2): (2,2)(3,2)
  showBoard('p06_v1 T4+L4+L3+I2', [('T4',0,0,0), ('L4',0,3,3), ('L3',2,0,2), ('I2',2,2,0)]);

  // p07: T4(4)+L4(4)+S4(4)+I2(2)=14
  // T4 원본 (0,0): (0,0)(0,1)(0,2)(1,1)
  // L4 rot1 (0,3): L4 rot1 = (0,0)(0,1)(0,2)(1,0) → (0,3)(0,4)(0,5)(1,3)
  // S4 원본 (1,2): (1,3)(1,4)(2,2)(2,3) → 겹침 (1,3)(1,4)
  // S4 원본 (2,0): (2,1)(2,2)(3,0)(3,1)
  // I2 세로 (1,2): (1,2)(2,2) → 겹침 (2,2)
  // I2 세로 (1,5): (1,5)(2,5)
  showBoard('p07_v1 T4+L4+S4+I2', [('T4',0,0,0), ('L4',0,3,1), ('S4',2,0,0), ('I2',1,5,0)]);

  // p08: O4(4)+S4(4)+L3(3)+I2(2)=13
  // O4 (0,0): (0,0)(0,1)(1,0)(1,1)
  // S4 rot1 (0,2): S4 rot1 = (0,0)(1,0)(1,1)(2,1) → (0,2)(1,2)(1,3)(2,3)
  // L3 rot1 (2,0): L3 rot1 = (0,0)(0,1)(1,0) → (2,0)(2,1)(3,0)
  // I2 가로 (2,2): (2,2)(2,3) → 겹침 (2,3)
  // I2 세로 (0,4): (0,4)(1,4)
  showBoard('p08_v1 O4+S4+L3+I2', [('O4',0,0,0), ('S4',0,2,1), ('L3',2,0,1), ('I2',0,4,0)]);

  // p09: L4(4)+Z4(4)+T4(4)+I2(2)=14
  // L4 rot1 (0,0): (0,0)(0,1)(0,2)(1,0)
  // Z4 원본 (0,3): (0,3)(0,4)(1,4)(1,5)
  // T4 rot2 (1,1): T4 rot2 = (0,1)(1,0)(1,1)(1,2) → (1,2)(2,1)(2,2)(2,3)
  // I2 세로 (1,5): (1,5)(2,5) → 겹침 (1,5)
  // I2 세로 (2,4): (2,4)(3,4)
  showBoard('p09_v1 L4+Z4+T4+I2', [('L4',0,0,1), ('Z4',0,3,0), ('T4',1,1,2), ('I2',2,4,0)]);

  // p10: P5(5)+T4(4)+L3(3)+I2(2)=14
  // P5 원본 (0,0): (0,0)(0,1)(1,0)(1,1)(2,0)
  // T4 rot3 (0,2): T4 rot3 = (0,0)(1,0)(1,1)(2,0) → (0,2)(1,2)(1,3)(2,2)
  // L3 rot1 (2,1): L3 rot1 = (0,0)(0,1)(1,0) → (2,1)(2,2)(3,1) → 겹침 (2,2)
  // L3 rot3 (2,3): L3 rot3 = (0,1)(1,0)(1,1) → (2,4)(3,3)(3,4)
  // I2 가로 (3,1): (3,1)(3,2)
  showBoard('p10_v1 P5+T4+L3+I2', [('P5',0,0,0), ('T4',0,2,3), ('L3',2,3,3), ('I2',3,1,1)]);

  // p11: L5(5)+S4(4)+L3(3)+I2(2)=14
  // L5 rot1 (0,0): L5 rot1 = (0,0)(0,1)(0,2)(0,3)(1,0)
  // S4 원본 (1,1): (1,2)(1,3)(2,1)(2,2)
  // L3 rot2 (1,4): L3 rot2 = (0,0)(0,1)(1,1) → (1,4)(1,5)(2,5)
  // I2 세로 (2,3): (2,3)(3,3)
  showBoard('p11_v1 L5+S4+L3+I2', [('L5',0,0,1), ('S4',1,1,0), ('L3',1,4,2), ('I2',2,3,0)]);

  // p12: T5(5)+L4(4)+Z4(4)+I2(2)=15
  // T5 원본 (0,0): (0,0)(0,1)(0,2)(1,1)(2,1)
  // L4 rot1 (0,3): L4 rot1 = (0,0)(0,1)(0,2)(1,0) → (0,3)(0,4)(0,5)(1,3)
  // Z4 rot1 (1,2): Z4 rot1 = (0,0)(1,0)(1,1)(2,1) → (1,2)(2,2)(2,3)(3,3)
  // I2 세로 (2,4): (2,4)(3,4)
  showBoard('p12_v1 T5+L4+Z4+I2', [('T5',0,0,0), ('L4',0,3,1), ('Z4',1,2,1), ('I2',2,4,0)]);
}
