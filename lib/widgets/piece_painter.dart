import 'package:flutter/material.dart';
import '../models/piece.dart';

/// 조각을 하나의 덩어리로 그리는 CustomPainter
class PiecePainter extends CustomPainter {
  final Piece piece;
  final double cellSize;
  final double opacity;

  PiecePainter({required this.piece, required this.cellSize, this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final cs = cellSize;
    final r = cs * 0.18; // 셀 모서리 반경
    final gap = cs * 0.04; // 셀 간격

    final color = piece.color.withValues(alpha: opacity);
    final highlight = HSLColor.fromColor(piece.color)
        .withLightness((HSLColor.fromColor(piece.color).lightness + 0.25).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: opacity);
    final shadow = HSLColor.fromColor(piece.color)
        .withLightness((HSLColor.fromColor(piece.color).lightness - 0.2).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: opacity);

    final cellSet = {for (final c in piece.cells) (c.row, c.col)};

    for (final cell in piece.cells) {
      final left = cell.col * cs + gap;
      final top = cell.row * cs + gap;
      final right = left + cs - gap * 2;
      final bottom = top + cs - gap * 2;

      // 인접 셀 확인 (이음새 처리)
      final hasRight = cellSet.contains((cell.row, cell.col + 1));
      final hasBottom = cellSet.contains((cell.row + 1, cell.col));
      final hasLeft = cellSet.contains((cell.row, cell.col - 1));
      final hasTop = cellSet.contains((cell.row - 1, cell.col));

      // 각 모서리 반경 결정 (인접 셀이 있으면 해당 방향 모서리 0)
      final tlR = (hasTop || hasLeft) ? 0.0 : r;
      final trR = (hasTop || hasRight) ? 0.0 : r;
      final brR = (hasBottom || hasRight) ? 0.0 : r;
      final blR = (hasBottom || hasLeft) ? 0.0 : r;

      // 인접 방향으로 gap 제거 (이음새 없애기)
      final l = hasLeft ? left - gap * 2 : left;
      final t = hasTop ? top - gap * 2 : top;
      final rr = hasRight ? right + gap * 2 : right;
      final b = hasBottom ? bottom + gap * 2 : bottom;

      final rect = RRect.fromLTRBAndCorners(
        l, t, rr, b,
        topLeft: Radius.circular(tlR),
        topRight: Radius.circular(trR),
        bottomRight: Radius.circular(brR),
        bottomLeft: Radius.circular(blR),
      );

      // 그라디언트 페인트
      final gradPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [highlight, color, shadow],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTRB(l, t, rr, b));

      // 그림자
      final shadowPaint = Paint()
        ..color = piece.color.withValues(alpha: opacity * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawRRect(rect.shift(const Offset(0, 3)), shadowPaint);

      // 본체
      canvas.drawRRect(rect, gradPaint);

      // 상단 광택 하이라이트
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.38);
      final shineRect = RRect.fromLTRBR(
        l + (rr - l) * 0.08,
        t + (b - t) * 0.06,
        l + (rr - l) * 0.45,
        t + (b - t) * 0.2,
        Radius.circular(cs * 0.06),
      );
      canvas.drawRRect(shineRect, shinePaint);
    }
  }

  @override
  bool shouldRepaint(PiecePainter old) =>
      old.piece != piece || old.cellSize != cellSize || old.opacity != opacity;
}
