import 'package:flutter/material.dart';
import '../models/piece.dart';

class PieceDragData {
  final Piece piece;
  final int grabRow;
  final int grabCol;

  const PieceDragData({
    required this.piece,
    required this.grabRow,
    required this.grabCol,
  });
}

class PieceWidget extends StatefulWidget {
  final Piece piece;
  final double cellSize;
  final void Function(Piece rotated)? onTransform;

  const PieceWidget({
    super.key,
    required this.piece,
    required this.cellSize,
    this.onTransform,
  });

  @override
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget> {
  late Piece _current;
  bool _isDragging = false;
  int _grabRow = 0;
  int _grabCol = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.piece;
  }

  @override
  void didUpdateWidget(PieceWidget old) {
    super.didUpdateWidget(old);
    if (old.piece.id != widget.piece.id) {
      _current = widget.piece;
    }
  }

  void _rotateCW() {
    setState(() => _current = _current.rotate());
    widget.onTransform?.call(_current);
  }

  void _rotateCCW() {
    // 반시계 = 시계방향 3번
    setState(() {
      _current = _current.rotate().rotate().rotate();
    });
    widget.onTransform?.call(_current);
  }

  void _flip() {
    setState(() => _current = _current.flip());
    widget.onTransform?.call(_current);
  }

  Widget _buildGrid({double opacity = 1.0}) {
    final rows = _current.maxRow + 1;
    final cols = _current.maxCol + 1;
    final cellSet = {for (final c in _current.cells) '${c.row},${c.col}'};
    final cs = widget.cellSize;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (r) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(cols, (c) {
              final filled = cellSet.contains('$r,$c');
              return Container(
                width: cs,
                height: cs,
                decoration: BoxDecoration(
                  color: filled ? _current.color : Colors.transparent,
                  borderRadius: filled ? BorderRadius.circular(4) : BorderRadius.zero,
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  // 탭한 로컬 위치로 어느 셀을 잡았는지 계산
  void _calcGrabCell(RenderBox box, Offset globalPos) {
    final local = box.globalToLocal(globalPos);
    final cs = widget.cellSize;
    int gr = (local.dy / cs).floor().clamp(0, _current.maxRow);
    int gc = (local.dx / cs).floor().clamp(0, _current.maxCol);
    final cellSet = {for (final c in _current.cells) '${c.row},${c.col}'};
    if (!cellSet.contains('$gr,$gc') && _current.cells.isNotEmpty) {
      gr = _current.cells.first.row;
      gc = _current.cells.first.col;
    }
    setState(() {
      _grabRow = gr;
      _grabCol = gc;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 조각 그리드 (드래그 가능)
        GestureDetector(
          onTap: _isDragging ? null : _rotateCW,
          onLongPress: _isDragging ? null : _flip,
          child: Draggable<PieceDragData>(
            data: PieceDragData(piece: _current, grabRow: _grabRow, grabCol: _grabCol),
            onDragStarted: () => setState(() => _isDragging = true),
            onDragEnd: (_) => setState(() => _isDragging = false),
            onDraggableCanceled: (v, o) => setState(() => _isDragging = false),
            feedback: Material(
              color: Colors.transparent,
              child: _buildGrid(opacity: 0.85),
            ),
            childWhenDragging: _buildGrid(opacity: 0.3),
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Listener(
                onPointerDown: (event) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  _calcGrabCell(box, event.position);
                },
                child: _buildGrid(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 변환 버튼
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TransformBtn(icon: Icons.rotate_left, onTap: _rotateCCW),
            const SizedBox(width: 4),
            _TransformBtn(icon: Icons.rotate_right, onTap: _rotateCW),
            const SizedBox(width: 4),
            _TransformBtn(icon: Icons.flip, onTap: _flip),
          ],
        ),
      ],
    );
  }
}

class _TransformBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TransformBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }
}
