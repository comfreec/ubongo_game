import 'dart:io';
import '../lib/data/puzzles.dart';
import '../lib/data/puzzle_solver.dart';

void main() {
  final puzzles = allBasePuzzles;
  int pass = 0, fail = 0;
  for (final p in puzzles) {
    final ok = hasSolution(p, p.pieceIds);
    if (ok) {
      pass++;
      print('OK  : ${p.id}');
    } else {
      fail++;
      print('FAIL: ${p.id}  조각=${p.pieceIds}');
    }
  }
  print('\n총 ${puzzles.length}개 중 통과: $pass, 실패: $fail');
  exit(fail > 0 ? 1 : 0);
}
