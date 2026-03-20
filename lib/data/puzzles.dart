import 'dart:math';
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/puzzle.dart';

final Map<String, Piece> allPieces = {
  // 빨강
  'I2': Piece(id:'I2', instanceId:'I2', color:const Color(0xFFE53935),
    cells:[(row:0,col:0),(row:1,col:0)]),
  // 보라
  'I3': Piece(id:'I3', instanceId:'I3', color:const Color(0xFF7B1FA2),
    cells:[(row:0,col:0),(row:1,col:0),(row:2,col:0)]),
  // 파랑
  'L3': Piece(id:'L3', instanceId:'L3', color:const Color(0xFF1565C0),
    cells:[(row:0,col:0),(row:1,col:0),(row:1,col:1)]),
  // 청록
  'I4': Piece(id:'I4', instanceId:'I4', color:const Color(0xFF00838F),
    cells:[(row:0,col:0),(row:1,col:0),(row:2,col:0),(row:3,col:0)]),
  // 노랑
  'O4': Piece(id:'O4', instanceId:'O4', color:const Color(0xFFF9A825),
    cells:[(row:0,col:0),(row:0,col:1),(row:1,col:0),(row:1,col:1)]),
  // 연두
  'T4': Piece(id:'T4', instanceId:'T4', color:const Color(0xFF558B2F),
    cells:[(row:0,col:0),(row:0,col:1),(row:0,col:2),(row:1,col:1)]),
  // 주황
  'L4': Piece(id:'L4', instanceId:'L4', color:const Color(0xFFE65100),
    cells:[(row:0,col:0),(row:1,col:0),(row:2,col:0),(row:2,col:1)]),
  // 민트
  'S4': Piece(id:'S4', instanceId:'S4', color:const Color(0xFF00695C),
    cells:[(row:0,col:1),(row:0,col:2),(row:1,col:0),(row:1,col:1)]),
  // 핑크
  'Z4': Piece(id:'Z4', instanceId:'Z4', color:const Color(0xFFC2185B),
    cells:[(row:0,col:0),(row:0,col:1),(row:1,col:1),(row:1,col:2)]),
  // 하늘
  'L5': Piece(id:'L5', instanceId:'L5', color:const Color(0xFF0277BD),
    cells:[(row:0,col:0),(row:1,col:0),(row:2,col:0),(row:3,col:0),(row:3,col:1)]),
  // 진빨강
  'T5': Piece(id:'T5', instanceId:'T5', color:const Color(0xFFB71C1C),
    cells:[(row:0,col:0),(row:0,col:1),(row:0,col:2),(row:1,col:1),(row:2,col:1)]),
  // 초록
  'P5': Piece(id:'P5', instanceId:'P5', color:const Color(0xFF2E7D32),
    cells:[(row:0,col:0),(row:0,col:1),(row:1,col:0),(row:1,col:1),(row:2,col:0)]),
};

Puzzle _fromPattern(String id, List<String> pattern, List<String> pieceIds) {
  final rows = pattern.length;
  final cols = pattern.map((r) => r.length).reduce((a, b) => a > b ? a : b);
  final grid = List.generate(rows, (r) =>
    List.generate(cols, (c) => c < pattern[r].length && pattern[r][c] == '#'));
  return Puzzle(id: id, rows: rows, cols: cols, grid: grid, pieceIds: pieceIds);
}

final List<Puzzle> _basePuzzles = [
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 쉬움 (3조각)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  _fromPattern('p01', ['.###','####','##..'], ['T4','L3','I2']),
  _fromPattern('p02', ['##..','####','.###'], ['S4','L3','I2']),
  _fromPattern('p03', ['###.','####','..##'], ['L4','L3','I2']),
  _fromPattern('p04', ['####','.###','..##'], ['T4','I3','I2']),
  _fromPattern('p05', ['..##','#####','###..'], ['L4','S4','I2']),
  _fromPattern('p14', ['##..','####','###.'], ['L4','I3','I2']),
  _fromPattern('p15', ['##..','####','###.'], ['S4','I3','I2']),
  _fromPattern('p16', ['##..','####','###.'], ['Z4','I3','I2']),
  _fromPattern('p17', ['.###','#####','##..'], ['T4','O4','I2']),
  _fromPattern('p18', ['###.','#####','..##'], ['L4','O4','I2']),

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 보통 (4조각)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  _fromPattern('p06', ['.###.','#####','#####'], ['T4','L4','L3','I2']),
  _fromPattern('p07', ['#####','.####','#####'], ['T4','L4','S4','I2']),
  _fromPattern('p08', ['#####','#####','.###.'], ['O4','S4','L3','I2']),
  _fromPattern('p09', ['#####','####.','#####'], ['L4','Z4','T4','I2']),
  _fromPattern('p10', ['#####','#####','####.'], ['P5','T4','L3','I2']),
  _fromPattern('p11', ['.####','#####','#####'], ['L5','S4','L3','I2']),
  _fromPattern('p12', ['####.','#####','#####','#....'], ['T5','L4','Z4','I2']),
  _fromPattern('p19', ['.###.','#####','#####'], ['O4','L4','L3','I2']),
  _fromPattern('p20', ['.###.','#####','#####'], ['O4','T4','L3','I2']),
  _fromPattern('p21', ['.###.','#####','#####'], ['S4','Z4','L3','I2']),
  _fromPattern('p22', ['#####','#####','####.'], ['T5','S4','L3','I2']),
  _fromPattern('p23', ['#####','#####','####.'], ['P5','L4','L3','I2']),
  _fromPattern('p24', ['#####','#####','####.'], ['L5','T4','L3','I2']),
  _fromPattern('p25', ['#####','#####','####.'], ['T5','O4','L3','I2']),
  _fromPattern('p26', ['#####','#####','####.'], ['P5','S4','L3','I2']),
  _fromPattern('p27', ['#####','#####','####.'], ['L5','L4','L3','I2']),
  _fromPattern('p28', ['#####','#####','####.'], ['T5','Z4','L3','I2']),
];

/// 매번 새로운 랜덤 순서로 섞인 퍼즐 리스트 반환
List<Puzzle> getShuffledPuzzles() {
  final list = [..._basePuzzles];
  list.shuffle(Random());
  return list;
}

/// 전체 퍼즐 수
int get totalPuzzleCount => _basePuzzles.length;
