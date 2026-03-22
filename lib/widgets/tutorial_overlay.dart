import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

class TutorialOverlay extends StatefulWidget {
  final Widget child;
  const TutorialOverlay({super.key, required this.child});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  bool _show = false;
  int _step = 0;
  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;

  static const _key = 'tutorial_done_v2';
  static const _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _checkFirst();
  }

  Future<void> _checkFirst() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_key) ?? false) && mounted) {
      setState(() => _show = true);
      _pageCtrl.forward();
    }
  }

  Future<void> _next() async {
    if (_step < _totalSteps - 1) {
      await _pageCtrl.reverse();
      setState(() => _step++);
      _pageCtrl.forward();
    } else {
      await _pageCtrl.reverse();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      if (mounted) setState(() => _show = false);
    }
  }

  Future<void> _skip() async {
    await _pageCtrl.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    if (mounted) setState(() => _show = false);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!_show) return widget.child;
    return Stack(children: [
      widget.child,
      FadeTransition(
        opacity: _pageFade,
        child: Container(
          color: Colors.black.withValues(alpha: 0.82),
          child: SafeArea(
            child: Column(children: [
              // 상단 바
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${s.tutProgress} ${_step + 1}/$_totalSteps',
                        style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    TextButton(
                      onPressed: _skip,
                      child: Text(s.tutSkip,
                          style: const TextStyle(color: Colors.white38, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              // 진행 바
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / _totalSteps,
                    minHeight: 4,
                    backgroundColor: Colors.white12,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 일러스트 영역
              Expanded(
                flex: 5,
                child: Builder(builder: (ctx) {
                  final s = S.of(ctx);
                  return _TutIllustration(
                    step: _step,
                    dragLabel: s.dragLabel,
                    boardLabel: s.boardLabel,
                    tapRotateLabel: s.tapRotateLabel,
                    longTapFlipLabel: s.longTapFlipLabel,
                    clearLabel: s.clearLabel,
                  );
                }),
              ),
              // 텍스트 카드
              Expanded(
                flex: 3,
                child: _TutTextCard(step: _step, onNext: _next),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ),
    ]);
  }
}

// ─── 일러스트 컨테이너 ───────────────────────────────────────────
class _TutIllustration extends StatefulWidget {
  final int step;
  final String dragLabel;
  final String boardLabel;
  final String tapRotateLabel;
  final String longTapFlipLabel;
  final String clearLabel;
  const _TutIllustration({
    required this.step,
    required this.dragLabel,
    required this.boardLabel,
    required this.tapRotateLabel,
    required this.longTapFlipLabel,
    required this.clearLabel,
  });

  @override
  State<_TutIllustration> createState() => _TutIllustrationState();
}

class _TutIllustrationState extends State<_TutIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void didUpdateWidget(_TutIllustration old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) {
      _ctrl.reset();
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox.expand(
        child: CustomPaint(
          painter: _stepPainter(widget.step, _ctrl.value),
        ),
      ),
    );
  }

  CustomPainter _stepPainter(int step, double t) {
    switch (step) {
      case 0: return _DragPainter(t, widget.dragLabel, widget.boardLabel);
      case 1: return _RotatePainter(t, widget.tapRotateLabel);
      case 2: return _FlipPainter(t, widget.longTapFlipLabel);
      default: return _ClearPainter(t, widget.clearLabel);
    }
  }
}

// ─── 텍스트 카드 ─────────────────────────────────────────────────
class _TutTextCard extends StatelessWidget {
  final int step;
  final VoidCallback onNext;

  const _TutTextCard({required this.step, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final titles = [s.tutStep1Title, s.tutStep2Title, s.tutStep3Title, s.tutStep4Title];
    final descs = [s.tutStep1Desc, s.tutStep2Desc, s.tutStep3Desc, s.tutStep4Desc];
    const colors = [Color(0xFF4D96FF), Color(0xFF6BCB77), Color(0xFFFF922B), Color(0xFFFFD93D)];

    final title = titles[step];
    final desc = descs[step];
    final color = colors[step];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 15, height: 1.6)),
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  step < 3 ? s.tutNext : s.tutStart,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 공통 드로잉 헬퍼 ────────────────────────────────────────────
void _drawPiece(Canvas canvas, Offset origin, List<(int r, int c)> cells,
    double cs, Color color, {double alpha = 1.0, double elevation = 0}) {
  final cellSet = {for (final c in cells) '${c.$1},${c.$2}'};
  final highlight = HSLColor.fromColor(color)
      .withLightness(
          (HSLColor.fromColor(color).lightness + 0.25).clamp(0.0, 1.0))
      .toColor()
      .withValues(alpha: alpha);
  final shadow = HSLColor.fromColor(color)
      .withLightness(
          (HSLColor.fromColor(color).lightness - 0.2).clamp(0.0, 1.0))
      .toColor()
      .withValues(alpha: alpha);
  final base = color.withValues(alpha: alpha);

  for (final cell in cells) {
    final hasR = cellSet.contains('${cell.$1},${cell.$2 + 1}');
    final hasB = cellSet.contains('${cell.$1 + 1},${cell.$2}');
    final hasL = cellSet.contains('${cell.$1},${cell.$2 - 1}');
    final hasT = cellSet.contains('${cell.$1 - 1},${cell.$2}');

    final gap = cs * 0.04;
    final r = cs * 0.18;
    final l = origin.dx + cell.$2 * cs + (hasL ? 0 : gap);
    final t = origin.dy + cell.$1 * cs + (hasT ? 0 : gap) - elevation;
    final rr = origin.dx + (cell.$2 + 1) * cs - (hasR ? 0 : gap);
    final b = origin.dy + (cell.$1 + 1) * cs - (hasB ? 0 : gap) - elevation;

    final tlR = (hasT || hasL) ? 0.0 : r;
    final trR = (hasT || hasR) ? 0.0 : r;
    final brR = (hasB || hasR) ? 0.0 : r;
    final blR = (hasB || hasL) ? 0.0 : r;

    final rect = RRect.fromLTRBAndCorners(l, t, rr, b,
        topLeft: Radius.circular(tlR),
        topRight: Radius.circular(trR),
        bottomRight: Radius.circular(brR),
        bottomLeft: Radius.circular(blR));

    // 그림자
    if (elevation > 0) {
      canvas.drawRRect(
          rect.shift(Offset(0, elevation + 2)),
          Paint()
            ..color = Colors.black.withValues(alpha: alpha * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    // 본체 그라디언트
    canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [highlight, base, shadow],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(Rect.fromLTRB(l, t, rr, b)));

    // 광택
    canvas.drawRRect(
        RRect.fromLTRBR(l + (rr - l) * 0.08, t + (b - t) * 0.06,
            l + (rr - l) * 0.45, t + (b - t) * 0.22, Radius.circular(cs * 0.06)),
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.35));
  }
}

void _drawBoard(Canvas canvas, Offset origin, int rows, int cols, double cs,
    {List<(int r, int c)>? filled, Color fillColor = Colors.transparent}) {
  final bgPaint = Paint()..color = const Color(0xFF0D1B2A);
  final boardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx, origin.dy, cols * cs, rows * cs),
      const Radius.circular(8));
  canvas.drawRRect(boardRect, bgPaint);

  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      final isFilled =
          filled?.any((f) => f.$1 == r && f.$2 == c) ?? false;
      final cellRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(origin.dx + c * cs + 1, origin.dy + r * cs + 1,
              cs - 2, cs - 2),
          const Radius.circular(4));
      canvas.drawRRect(
          cellRect,
          Paint()
            ..color = isFilled
                ? fillColor.withValues(alpha: 0.8)
                : const Color(0xFF1E3A5F));
    }
  }
}

// ─── Step 0: 드래그 애니메이션 ───────────────────────────────────
class _DragPainter extends CustomPainter {
  final double t;
  final String dragLabel;
  final String boardLabel;
  _DragPainter(this.t, this.dragLabel, this.boardLabel);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final cs = size.width * 0.09;

    // 보드 (오른쪽)
    final boardOrigin = Offset(cx + cs * 0.5, cy - cs * 1.5);
    _drawBoard(canvas, boardOrigin, 3, 3, cs);

    // 조각 (L자)
    final piece = [(0, 0), (1, 0), (2, 0), (2, 1)];
    final color = const Color(0xFF4D96FF);

    // 드래그 경로: 왼쪽 → 보드 위
    final startX = cx - cs * 2.5;
    final startY = cy - cs * 0.5;
    final endX = boardOrigin.dx;
    final endY = boardOrigin.dy;

    // 0~0.6: 이동, 0.6~0.8: 착지, 0.8~1.0: 대기
    final moveT = (t / 0.7).clamp(0.0, 1.0);
    final eased = Curves.easeInOut.transform(moveT);

    final px = startX + (endX - startX) * eased;
    final py = startY + (endY - startY) * eased - sin(eased * pi) * cs * 1.5;
    final elevation = t < 0.7 ? (1 - eased) * cs * 0.3 + cs * 0.2 : 0.0;
    final alpha = t > 0.85 ? 1.0 - (t - 0.85) / 0.15 * 0.3 : 1.0;

    // 손가락 커서
    if (t < 0.7) {
      final fingerX = px + cs * 0.5;
      final fingerY = py + cs * 1.5;
      canvas.drawCircle(Offset(fingerX, fingerY), cs * 0.35,
          Paint()..color = Colors.white.withValues(alpha: 0.6));
      canvas.drawCircle(Offset(fingerX, fingerY), cs * 0.22,
          Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    _drawPiece(canvas, Offset(px, py), piece, cs, color,
        alpha: alpha, elevation: elevation);

    // 배치 완료 시 초록 하이라이트
    if (t > 0.7) {
      final glowAlpha = ((t - 0.7) / 0.3).clamp(0.0, 1.0) * 0.5;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(boardOrigin.dx, boardOrigin.dy, cs * 2, cs * 3),
              const Radius.circular(6)),
          Paint()
            ..color = Colors.greenAccent.withValues(alpha: glowAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // 라벨
    _drawLabel(canvas, Offset(cx - cs * 2.5, cy + cs * 2), dragLabel, size);
    _drawLabel(canvas, Offset(boardOrigin.dx + cs, boardOrigin.dy + cs * 3.5),
        boardLabel, size);
  }

  @override
  bool shouldRepaint(_DragPainter old) => old.t != t;
}

// ─── Step 1: 회전 애니메이션 ─────────────────────────────────────
class _RotatePainter extends CustomPainter {
  final double t;
  final String label;
  _RotatePainter(this.t, this.label);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final cs = size.width * 0.1;

    final piece = [(0, 0), (1, 0), (2, 0), (2, 1)];
    final color = const Color(0xFF6BCB77);

    // 회전 각도 (0 → 90도)
    final rotT = Curves.elasticOut.transform(t.clamp(0.0, 1.0));
    final angle = rotT * pi / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    _drawPiece(canvas, Offset(-cs, -cs * 1.5), piece, cs, color);
    canvas.restore();

    // 회전 화살표 호
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final arcRect = Rect.fromCenter(
        center: Offset(cx, cy), width: cs * 4, height: cs * 4);
    canvas.drawArc(arcRect, -pi * 0.8, pi * 0.6 * t, false, arrowPaint);

    // 화살표 머리
    if (t > 0.1) {
      final arrowAngle = -pi * 0.8 + pi * 0.6 * t;
      final ax = cx + cs * 2 * cos(arrowAngle);
      final ay = cy + cs * 2 * sin(arrowAngle);
      final headPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      final path = Path();
      path.moveTo(ax, ay);
      path.lineTo(ax - cs * 0.25 * cos(arrowAngle - 0.5),
          ay - cs * 0.25 * sin(arrowAngle - 0.5));
      path.lineTo(ax - cs * 0.25 * cos(arrowAngle + 0.5),
          ay - cs * 0.25 * sin(arrowAngle + 0.5));
      path.close();
      canvas.drawPath(path, headPaint);
    }

    // 탭 이펙트
    if (t < 0.3) {
      final rippleAlpha = (1 - t / 0.3) * 0.6;
      canvas.drawCircle(Offset(cx, cy), cs * 1.5 * (t / 0.3 + 0.5),
          Paint()
            ..color = Colors.white.withValues(alpha: rippleAlpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    _drawLabel(canvas, Offset(cx, cy + cs * 3.2), label, size);
  }

  @override
  bool shouldRepaint(_RotatePainter old) => old.t != t;
}

// ─── Step 2: 반전 애니메이션 ─────────────────────────────────────
class _FlipPainter extends CustomPainter {
  final double t;
  final String label;
  _FlipPainter(this.t, this.label);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final cs = size.width * 0.1;

    final piece = [(0, 0), (1, 0), (2, 0), (2, 1)];
    final color = const Color(0xFFFF922B);

    // 0~0.4: 대기, 0.4~0.7: 뒤집기, 0.7~1.0: 완료
    final flipT = ((t - 0.3) / 0.5).clamp(0.0, 1.0);
    final scaleX = cos(flipT * pi);
    final absScale = scaleX.abs();

    // 뒤집힌 조각 (좌우 반전)
    final flippedPiece = absScale < 0.5
        ? [(0, 1), (1, 1), (2, 1), (2, 0)] // 반전된 L
        : piece;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scaleX, 1.0);
    _drawPiece(canvas, Offset(-cs, -cs * 1.5), flippedPiece, cs, color,
        elevation: absScale * cs * 0.2);
    canvas.restore();

    // 길게 누르기 표시
    if (t < 0.3) {
      final progress = t / 0.3;
      canvas.drawCircle(
          Offset(cx, cy),
          cs * 0.4,
          Paint()..color = Colors.white.withValues(alpha: 0.7));
      canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, cy), width: cs, height: cs),
          -pi / 2,
          2 * pi * progress,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    }

    // 반전 완료 화살표
    if (t > 0.6) {
      final alpha = ((t - 0.6) / 0.4).clamp(0.0, 1.0) * 0.7;
      final arrowPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      // 좌우 화살표
      canvas.drawLine(Offset(cx - cs * 2.5, cy), Offset(cx - cs * 1.5, cy - cs * 0.4), arrowPaint);
      canvas.drawLine(Offset(cx - cs * 2.5, cy), Offset(cx - cs * 1.5, cy + cs * 0.4), arrowPaint);
      canvas.drawLine(Offset(cx - cs * 2.5, cy), Offset(cx + cs * 2.5, cy), arrowPaint);
      canvas.drawLine(Offset(cx + cs * 2.5, cy), Offset(cx + cs * 1.5, cy - cs * 0.4), arrowPaint);
      canvas.drawLine(Offset(cx + cs * 2.5, cy), Offset(cx + cs * 1.5, cy + cs * 0.4), arrowPaint);
    }

    _drawLabel(canvas, Offset(cx, cy + cs * 3.2), label, size);
  }

  @override
  bool shouldRepaint(_FlipPainter old) => old.t != t;
}

// ─── Step 3: 완성 애니메이션 ─────────────────────────────────────
class _ClearPainter extends CustomPainter {
  final double t;
  final String label;
  _ClearPainter(this.t, this.label);

  static const _boardCells = [
    (0, 0), (0, 1), (0, 2),
    (1, 0), (1, 1), (1, 2),
    (2, 0), (2, 1), (2, 2),
  ];
  static const _colors = [
    Color(0xFF4D96FF), Color(0xFF4D96FF), Color(0xFF6BCB77),
    Color(0xFFFF922B), Color(0xFF4D96FF), Color(0xFF6BCB77),
    Color(0xFFFF922B), Color(0xFFFF922B), Color(0xFF6BCB77),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final cs = size.width * 0.1;

    final boardOrigin = Offset(cx - cs * 1.5, cy - cs * 1.5);

    // 보드 배경
    _drawBoard(canvas, boardOrigin, 3, 3, cs);

    // 셀들이 순서대로 채워짐
    for (int i = 0; i < _boardCells.length; i++) {
      final cellT = (t * 1.5 - i * 0.12).clamp(0.0, 1.0);
      if (cellT <= 0) continue;
      final cell = _boardCells[i];
      final color = _colors[i];
      final scale = Curves.elasticOut.transform(cellT.clamp(0.0, 1.0));

      canvas.save();
      final cellCx = boardOrigin.dx + cell.$2 * cs + cs / 2;
      final cellCy = boardOrigin.dy + cell.$1 * cs + cs / 2;
      canvas.translate(cellCx, cellCy);
      canvas.scale(scale, scale);
      canvas.translate(-cellCx, -cellCy);

      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(boardOrigin.dx + cell.$2 * cs + 1,
              boardOrigin.dy + cell.$1 * cs + 1, cs - 2, cs - 2),
          const Radius.circular(4));
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: 0.85));
      // 광택
      canvas.drawRRect(
          RRect.fromLTRBR(
              boardOrigin.dx + cell.$2 * cs + cs * 0.1,
              boardOrigin.dy + cell.$1 * cs + cs * 0.08,
              boardOrigin.dx + cell.$2 * cs + cs * 0.55,
              boardOrigin.dy + cell.$1 * cs + cs * 0.28,
              const Radius.circular(3)),
          Paint()..color = Colors.white.withValues(alpha: 0.3));
      canvas.restore();
    }

    // 완성 후 별 + 빛 효과
    if (t > 0.8) {
      final glowT = ((t - 0.8) / 0.2).clamp(0.0, 1.0);
      // 빛 방사
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        final len = cs * 1.5 * glowT;
        canvas.drawLine(
            Offset(cx, cy - cs * 0.2),
            Offset(cx + cos(angle) * len, cy - cs * 0.2 + sin(angle) * len),
            Paint()
              ..color = Colors.amber.withValues(alpha: glowT * 0.6)
              ..strokeWidth = 2
              ..strokeCap = StrokeCap.round);
      }
      // 별
      _drawStar(canvas, Offset(cx, cy - cs * 0.2), cs * 0.6 * glowT,
          Colors.amber.withValues(alpha: glowT));
    }

    _drawLabel(canvas, Offset(cx, boardOrigin.dy + cs * 3.8),
        label, size);
  }

  void _drawStar(Canvas canvas, Offset center, double r, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outer = Offset(
          center.dx + r * cos(i * 2 * pi / 5 - pi / 2),
          center.dy + r * sin(i * 2 * pi / 5 - pi / 2));
      final inner = Offset(
          center.dx + r * 0.4 * cos((i * 2 + 1) * pi / 5 - pi / 2),
          center.dy + r * 0.4 * sin((i * 2 + 1) * pi / 5 - pi / 2));
      if (i == 0) path.moveTo(outer.dx, outer.dy);
      else path.lineTo(outer.dx, outer.dy);
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ClearPainter old) => old.t != t;
}

// ─── 라벨 헬퍼 ───────────────────────────────────────────────────
void _drawLabel(Canvas canvas, Offset pos, String text, Size size) {
  final tp = TextPainter(
    text: TextSpan(
        text: text,
        style: const TextStyle(
            color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy));
}
