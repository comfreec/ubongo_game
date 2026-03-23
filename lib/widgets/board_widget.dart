import 'package:flutter/material.dart';
import '../models/puzzle.dart';
import '../models/game_state.dart';
import '../models/piece.dart';
import 'piece_widget.dart' show PieceDragData;

class BoardWidget extends StatefulWidget {
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

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with TickerProviderStateMixin {
  // 최근 배치된 셀들의 바운스 애니메이션
  final Map<String, AnimationController> _bounceCtrl = {};
  final Map<String, Animation<double>> _bounceAnim = {};
  Set<String> _prevPlacedKeys = {};

  @override
  void didUpdateWidget(BoardWidget old) {
    super.didUpdateWidget(old);
    final newKeys = _placedKeys();
    final added = newKeys.difference(_prevPlacedKeys);
    for (final key in added) {
      _startBounce(key);
    }
    _prevPlacedKeys = newKeys;
  }

  Set<String> _placedKeys() {
    final keys = <String>{};
    for (final pp in widget.placedPieces) {
      for (final c in pp.occupiedCells) {
        keys.add('${c.row},${c.col}');
      }
    }
    return keys;
  }

  void _startBounce(String key) {
    _bounceCtrl[key]?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    final anim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.92), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.04), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    _bounceCtrl[key] = ctrl;
    _bounceAnim[key] = anim;
    ctrl.forward().then((_) {
      _bounceCtrl.remove(key)?.dispose();
      _bounceAnim.remove(key);
    });
  }

  @override
  void dispose() {
    for (final c in _bounceCtrl.values) c.dispose();
    super.dispose();
  }

  PlacedPiece? _placedPieceAt(int row, int col) {
    for (final pp in widget.placedPieces) {
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
      if (r < 0 || r >= widget.puzzle.rows || cc < 0 || cc >= widget.puzzle.cols) return false;
      if (!widget.puzzle.grid[r][cc]) return false;
      if (_cellColor(r, cc) != null) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.04),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.puzzle.rows, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.puzzle.cols, (col) {
              final active = widget.puzzle.grid[row][col];
              final placedPiece = _placedPieceAt(row, col);
              final placed = placedPiece?.piece.color;

              if (!active) {
                return SizedBox(width: widget.cellSize, height: widget.cellSize);
              }

              final cellKey = '$row,$col';
              final bounceAnim = _bounceAnim[cellKey];

              return DragTarget<PieceDragData>(
                onWillAcceptWithDetails: (details) {
                  final d = details.data;
                  return _canPlace(d.piece, row - d.grabRow, col - d.grabCol);
                },
                onAcceptWithDetails: (details) {
                  final d = details.data;
                  final placeRow = row - d.grabRow;
                  final placeCol = col - d.grabCol;
                  if (_canPlace(d.piece, placeRow, placeCol)) {
                    widget.onDrop(d.piece, placeRow, placeCol);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  Color baseColor;
                  bool isPlaced = false;
                  bool isHover = false;
                  bool isInvalid = false;

                  if (placed != null) {
                    baseColor = placed;
                    isPlaced = true;
                  } else if (candidateData.isNotEmpty) {
                    final d = candidateData.first!;
                    final valid = _canPlace(d.piece, row - d.grabRow, col - d.grabCol);
                    baseColor = valid ? d.piece.color : Colors.red;
                    isHover = valid;
                    isInvalid = !valid;
                  } else {
                    baseColor = const Color(0xFF1E3A5F);
                  }

                  Widget cell = _BoardCell(
                    size: widget.cellSize,
                    color: baseColor,
                    isPlaced: isPlaced,
                    isHover: isHover,
                    isInvalid: isInvalid,
                  );

                  // 바운스 애니메이션 적용
                  if (bounceAnim != null) {
                    cell = AnimatedBuilder(
                      animation: bounceAnim,
                      builder: (_, child) => Transform.scale(
                        scale: bounceAnim.value,
                        child: child,
                      ),
                      child: cell,
                    );
                  }

                  if (placedPiece != null && widget.onRemove != null) {
                    return GestureDetector(
                      onTap: () => widget.onRemove!(placedPiece),
                      child: cell,
                    );
                  }
                  return cell;
                },
              );
            }),
          );
        }),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  final double size;
  final Color color;
  final bool isPlaced;
  final bool isHover;
  final bool isInvalid;

  const _BoardCell({
    required this.size,
    required this.color,
    required this.isPlaced,
    required this.isHover,
    required this.isInvalid,
  });

  @override
  Widget build(BuildContext context) {
    final margin = size * 0.04;
    final radius = size * 0.18;

    if (!isPlaced && !isHover && !isInvalid) {
      return SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: EdgeInsets.all(margin),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A5F), Color(0xFF0D2040)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 3,
                  offset: const Offset(1, 2),
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final alpha = isHover ? 0.6 : (isInvalid ? 0.5 : 1.0);
    final highlight = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness + 0.25).clamp(0.0, 1.0))
        .toColor();
    final shadow = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness - 0.2).clamp(0.0, 1.0))
        .toColor();

    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(margin),
        child: Opacity(
          opacity: alpha,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [highlight, color, shadow],
                stops: const [0.0, 0.45, 1.0],
              ),
              boxShadow: isPlaced
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 3,
                        offset: const Offset(1, 2),
                      ),
                    ]
                  : [],
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(left: size * 0.08, top: size * 0.06),
                child: Container(
                  width: size * 0.35,
                  height: size * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.06),
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
