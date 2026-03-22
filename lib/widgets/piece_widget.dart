import 'package:flutter/material.dart';
import '../models/piece.dart';
import 'piece_painter.dart';

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

class _PieceWidgetState extends State<PieceWidget>
    with SingleTickerProviderStateMixin {
  late Piece _current;
  bool _isDragging = false;
  int _grabRow = 0;
  int _grabCol = 0;

  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _current = widget.piece;
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(PieceWidget old) {
    super.didUpdateWidget(old);
    if (old.piece.instanceId != widget.piece.instanceId) {
      _current = widget.piece;
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _rotateCW() {
    setState(() => _current = _current.rotate());
    widget.onTransform?.call(_current);
  }

  void _flip() {
    setState(() => _current = _current.flip());
    widget.onTransform?.call(_current);
  }

  void _rotateCCW() {
    setState(() => _current = _current.rotate().rotate().rotate());
    widget.onTransform?.call(_current);
  }

  Size _pieceSize() {
    final rows = _current.maxRow + 1;
    final cols = _current.maxCol + 1;
    return Size(cols * widget.cellSize, rows * widget.cellSize);
  }

  Widget _buildPainter({double opacity = 1.0}) {
    final sz = _pieceSize();
    return CustomPaint(
      size: sz,
      painter: PiecePainter(
        piece: _current,
        cellSize: widget.cellSize,
        opacity: opacity,
      ),
    );
  }

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
        GestureDetector(
          onTap: _isDragging ? null : _rotateCW,
          onLongPress: _isDragging ? null : _flip,
          child: Draggable<PieceDragData>(
            data: PieceDragData(piece: _current, grabRow: _grabRow, grabCol: _grabCol),
            onDragStarted: () {
              setState(() => _isDragging = true);
              _scaleCtrl.forward();
            },
            onDragEnd: (_) {
              setState(() => _isDragging = false);
              _scaleCtrl.reverse();
            },
            onDraggableCanceled: (_, __) {
              setState(() => _isDragging = false);
              _scaleCtrl.reverse();
            },
            feedback: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: _buildPainter(opacity: 0.9),
              ),
            ),
            childWhenDragging: _buildPainter(opacity: 0.25),
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Listener(
                onPointerDown: (event) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  _calcGrabCell(box, event.position);
                },
                child: _buildPainter(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
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
