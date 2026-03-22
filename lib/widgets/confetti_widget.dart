import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool active;
  const ConfettiOverlay({super.key, required this.active});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _particles = [];
    if (widget.active) _launch();
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _launch();
  }

  void _launch() {
    _particles = List.generate(80, (_) => _Particle(_rng));
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active && !_ctrl.isAnimating) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(_particles, _ctrl.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Particle {
  final double x;       // 시작 x (0~1 비율)
  final double speed;   // 낙하 속도
  final double drift;   // 좌우 흔들림
  final double size;
  final Color color;
  final double phase;   // 흔들림 위상
  final double rotation;
  final bool isRect;    // 사각형 or 원

  _Particle(Random rng)
      : x = rng.nextDouble(),
        speed = 0.3 + rng.nextDouble() * 0.7,
        drift = (rng.nextDouble() - 0.5) * 0.15,
        size = 6 + rng.nextDouble() * 8,
        color = _colors[rng.nextInt(_colors.length)],
        phase = rng.nextDouble() * pi * 2,
        rotation = rng.nextDouble() * pi * 2,
        isRect = rng.nextBool();

  static const _colors = [
    Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77),
    Color(0xFF4D96FF), Color(0xFFFF922B), Color(0xFFCC5DE8),
    Color(0xFF20C997), Color(0xFFFF8CC8),
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t; // 0~1

  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (t * p.speed).clamp(0.0, 1.0);
      final y = -20 + size.height * 1.1 * progress;
      final x = p.x * size.width + sin(progress * pi * 4 + p.phase) * size.width * p.drift;
      final opacity = progress < 0.7 ? 1.0 : (1.0 - (progress - 0.7) / 0.3);
      final rot = p.rotation + progress * pi * 3;

      final paint = Paint()..color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);

      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
