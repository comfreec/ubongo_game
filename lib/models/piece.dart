import 'package:flutter/material.dart';

/// 조각의 셀 좌표 (행, 열)
typedef Cell = ({int row, int col});

class Piece {
  final String id;
  final String instanceId; // 각 조각 인스턴스 고유 ID
  final List<Cell> cells;
  final Color color;

  const Piece({required this.id, required this.instanceId, required this.cells, required this.color});

  Piece rotate() {
    final rotated = cells.map((c) => (row: c.col, col: -c.row)).toList();
    return _normalize(rotated);
  }

  Piece flip() {
    final flipped = cells.map((c) => (row: c.row, col: -c.col)).toList();
    return _normalize(flipped);
  }

  Piece _normalize(List<Cell> newCells) {
    final minRow = newCells.map((c) => c.row).reduce((a, b) => a < b ? a : b);
    final minCol = newCells.map((c) => c.col).reduce((a, b) => a < b ? a : b);
    final normalized =
        newCells.map((c) => (row: c.row - minRow, col: c.col - minCol)).toList();
    return Piece(id: id, instanceId: instanceId, cells: normalized, color: color);
  }

  int get maxRow => cells.map((c) => c.row).reduce((a, b) => a > b ? a : b);
  int get maxCol => cells.map((c) => c.col).reduce((a, b) => a > b ? a : b);
}
