import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onDone;
  const SplashScreen({super.key, this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _blocksCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    _blocksCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn),
    );

    _blocksCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _logoCtrl.forward();
      }
    });

    // 2.2초 후 홈 화면으로
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      if (widget.onDone != null) {
        widget.onDone!();
      } else {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _blocksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 블록 조립 애니메이션
            SizedBox(
              width: 120,
              height: 120,
              child: AnimatedBuilder(
                animation: _blocksCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _BlockAssemblePainter(_blocksCtrl.value),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 타이틀
            AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Column(
                    children: [
                      Text(
                        S.of(context).appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.of(context).appSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 블록 4개가 날아와서 조립되는 애니메이션
class _BlockAssemblePainter extends CustomPainter {
  final double t; // 0~1

  _BlockAssemblePainter(this.t);

  static const _cellSize = 28.0;
  static const _gap = 2.0;

  // 최종 위치 (2x2 그리드 기준)
  static const _finalPositions = [
    Offset(0, 0), Offset(1, 0), Offset(0, 1), Offset(1, 1),
  ];

  // 시작 위치 (바깥에서 날아옴)
  static const _startOffsets = [
    Offset(-3, -3), Offset(3, -3), Offset(-3, 3), Offset(3, 3),
  ];

  static const _colors = [
    Color(0xFF4D96FF), Color(0xFF6BCB77),
    Color(0xFFFF922B), Color(0xFFCC5DE8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final step = _cellSize + _gap;

    // 전체 그리드 중심 오프셋
    final gridOffX = -step / 2;
    final gridOffY = -step / 2;

    final eased = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));

    for (int i = 0; i < 4; i++) {
      final finalPos = _finalPositions[i];
      final startOff = _startOffsets[i];

      final fx = cx + gridOffX + finalPos.dx * step;
      final fy = cy + gridOffY + finalPos.dy * step;
      final sx = cx + startOff.dx * step * 2;
      final sy = cy + startOff.dy * step * 2;

      final x = sx + (fx - sx) * eased;
      final y = sy + (fy - sy) * eased;

      final paint = Paint()
        ..color = _colors[i]
        ..style = PaintingStyle.fill;

      // 그림자
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3 * eased)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 2, y + 2, _cellSize, _cellSize),
          const Radius.circular(6),
        ),
        shadowPaint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, _cellSize, _cellSize),
          const Radius.circular(6),
        ),
        paint,
      );

      // 하이라이트
      final hlPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 3, y + 3, _cellSize - 6, 6),
          const Radius.circular(3),
        ),
        hlPaint,
      );
    }

    // 완성 후 반짝임
    if (t > 0.85) {
      final glowT = ((t - 0.85) / 0.15).clamp(0.0, 1.0);
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15 * sin(glowT * pi))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(cx, cy), 40 * glowT, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_BlockAssemblePainter old) => old.t != t;
}
