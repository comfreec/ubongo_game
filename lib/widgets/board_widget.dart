import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import 'piece_widget.dart' show PieceDragData;

class BoardWidget extends StatelessWidget {
  final Puzzle puzzle;
  final List<PlacedPiece> placedPieces;
  final double cellSize;
  final void Function(Piece piece, int row, int col) onDrop;
  final void Function(PlacedPiece pp)? onRemove;

  const BoardWidget({
    super.key,
    required this.puzzle,
    required this.placedPieces,
    required this.cellSize,
    required this.onDrop,
    this.onRemove,
  });

  PlacedPiece? _placedPieceAt(int row, int col) {
    for (final pp in placedPieces) {
      for (final c in pp.occupiedCells) {
        if (c.row == row && c.col == col) return pp;
      }
    }
    return null;
  }

  Color? _cellColor(int row, int col) => _placedPieceAt(row, col)?.piece.color;

  bool _canPlace(Piece piece, int row, int col) {
    for (final c in piece.cells) {
      final r = row + c.row;
      final cc = col + c.col;
      if (r < 0 || r >= puzzle.rows || cc < 0 || cc >= puzzle.cols) return false;
      if (!puzzle.grid[r][cc]) return false;
      if (_cellColor(r, cc) != null) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(puzzle.rows, (row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(puzzle.cols, (col) {
            final active = puzzle.grid[row][col];
            final placedPiece = _placedPieceAt(row, col);
            final placed = placedPiece?.piece.color;

            if (!active) {
              return SizedBox(width: cellSize, height: cellSize);
            }

            return DragTarget<PieceDragData>(
              onWillAcceptWithDetails: (details) {
                final d = details.data;
                final placeRow = row - d.grabRow;
                final placeCol = col - d.grabCol;
                return _canPlace(d.piece, placeRow, placeCol);
              },
              onAcceptWithDetails: (details) {
                final d = details.data;
                final placeRow = row - d.grabRow;
                final placeCol = col - d.grabCol;
                if (_canPlace(d.piece, placeRow, placeCol)) {
                  onDrop(d.piece, placeRow, placeCol);
                }
              },
              builder: (context, candidateData, rejectedData) {
                Color bg;
                if (placed != null) {
                  bg = placed;
                } else if (candidateData.isNotEmpty) {
                  final d = candidateData.first!;
                  final placeRow = row - d.grabRow;
                  final placeCol = col - d.grabCol;
                  final valid = _canPlace(d.piece, placeRow, placeCol);
                  bg = valid
                      ? d.piece.color.withValues(alpha: 0.5)
                      : Colors.red.withValues(alpha: 0.4);
                } else {
                  bg = Colors.grey.shade300;
                }

                // 배치된 조각은 탭으로 제거 가능
                final cell = Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(color: Colors.black26, width: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );

                if (placedPiece != null && onRemove != null) {
                  return GestureDetector(
                    onTap: () => onRemove!(placedPiece),
                    child: cell,
                  );
                }
                return cell;
              },
            );
          }),
        );
      }),
    );
  }
}
