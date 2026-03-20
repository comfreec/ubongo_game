typedef Cell = ({int row, int col});
class Piece {
  final String id; final List<Cell> cells;
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
  'L3': Piece('L3', [(row:0,col:0),(row:1,col:0),(row:1,col:1)]),
  'S4': Piece('S4', [(row:0,col:1),(row:0,col:2),(row:1,col:0),(row:1,col:1)]),
};
List<List<bool>> parsePattern(List<String> p) {
  final rows = p.length, cols = p.map((r) => r.length).reduce((a,b) => a>b?a:b);
  return List.generate(rows, (r) => List.generate(cols, (c) => c < p[r].length && p[r][c] == '#'));
}
List<Piece> allVariants(Piece p) {
  final seen = <String>{}; final result = <Piece>[]; Piece cur = p;
  for (int f = 0; f < 2; f++) { for (int r = 0; r < 4; r++) { final key = cur.cells.map((c) => '${c.row},${c.col}').join('|'); if (seen.add(key)) result.add(cur); cur = cur.rotate(); } cur = cur.flip(); }
  return result;
}
bool solve(List<List<int>> board, List<Piece> rem, int rows, int cols) {
  if (rem.isEmpty) { for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++) if (board[r][c] == 0) return false; return true; }
  int fr = -1, fc = -1;
  outer: for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++) if (board[r][c] == 0) { fr = r; fc = c; break outer; }
  if (fr == -1) return false;
  for (int i = 0; i < rem.length; i++) for (final v in allVariants(rem[i])) for (final anchor in v.cells) {
    final pr = fr-anchor.row, pc = fc-anchor.col;
    if (_can(board,v,pr,pc,rows,cols)) { _place(board,v,pr,pc,i+1); final nr=[...rem]..removeAt(i); if (solve(board,nr,rows,cols)) return true; _unplace(board,v,pr,pc); }
  }
  return false;
}
bool _can(List<List<int>> b, Piece p, int row, int col, int rows, int cols) { for (final c in p.cells) { final r=row+c.row,cc=col+c.col; if (r<0||r>=rows||cc<0||cc>=cols||b[r][cc]!=0) return false; } return true; }
void _place(List<List<int>> b, Piece p, int row, int col, int val) { for (final c in p.cells) b[row+c.row][col+c.col]=val; }
void _unplace(List<List<int>> b, Piece p, int row, int col) { for (final c in p.cells) b[row+c.row][col+c.col]=0; }
bool has(List<String> pattern, List<String> ids) {
  final grid = parsePattern(pattern); final rows=grid.length, cols=grid[0].length;
  final board = List.generate(rows,(r)=>List.generate(cols,(c)=>grid[r][c]?0:-1));
  return solve(board, ids.map((id)=>pieces[id]!).toList(), rows, cols);
}

void main() {
  // p02 현재 보드: ##.. / #### / .###
  final board = ['##..','####','.###'];
  final ids = ['S4','L3','I2'];
  final cnt = board.fold(0, (s,r) => s + r.split('').where((c)=>c=='#').length);
  print('보드 칸 수: $cnt');
  print('조각 합계: 4+3+2=9');
  final ok = has(board, ids);
  print('해답 있음: $ok');

  // 해답 있는 다른 S4+L3+I2 패턴들
  print('\nS4+L3+I2 해답 있는 패턴:');
  final candidates = [
    ['##..','####','.###'],
    ['.###','####','##..'],
    ['###.','####','..##'],
    ['..##','####','###.'],
    ['####','.###','..##'],
    ['##..','#####','..##'],
    ['.###','#####','#...'],
    ['#...','#####','.###'],
    ['####','#####','....'],  // 9칸 아님
  ];
  for (final p in candidates) {
    final c = p.fold(0, (s,r) => s + r.split('').where((x)=>x=='#').length);
    if (c != 9) { print('SKIP (${c}칸): ${p.join(" | ")}'); continue; }
    final r = has(p, ids);
    print('${r?"✓":"✗"}  ${p.join(" | ")}');
  }
}
