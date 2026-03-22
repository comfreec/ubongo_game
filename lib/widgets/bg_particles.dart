import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class BgParticles extends StatefulWidget {
  const BgParticles({super.key});

  @override
  State<BgParticles> createState() => _BgParticlesState();
}

class _BgParticlesState extends State<BgParticles> {
  late Ticker _ticker;
  late List<_Block> _blocks;
  Duration _last = Duration.zero;
  double _t = 0;
  final _rng = Random(42);

  @override
  void initState() {
    super.initState();
    _blocks = List.generate(22, (_) => _Block(_rng));
    _ticker = Ticker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_last == Duration.zero) {
      _last = elapsed;
      return;
    }
    final dt = (elapsed - _last).inMicroseconds / 1e6; // 초 단위 delta
    _last = elapsed;
    setState(() {
      _t += dt;
      for (final b in _blocks) {
        b.update(dt);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _BgPainter(_blocks),
        isComplex: true,
        willChange: true,
      ),
    );
  }
}

class _Block {
  double x;
  double y;       // 0~1 (화면 비율)
  final double speed;
  final double size;
  final Color color;
  double rotation;
  final double rotSpeed;
  final List<(int, int)> shape;

  _Block(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        speed = 0.04 + rng.nextDouble() * 0.06,  // 훨씬 빠르게
        size = 12 + rng.nextDouble() * 18,
        color = _colors[rng.nextInt(_colors.length)],
        rotation = rng.nextDouble() * pi * 2,
        rotSpeed = (rng.nextDouble() - 0.5) * 1.2,  // 회전도 빠르게
        shape = _shapes[rng.nextInt(_shapes.length)];

  void update(double dt) {
    y -= speed * dt;  // 위로 올라감
    rotation += rotSpeed * dt;
    if (y < -0.15) {
      y = 1.1;  // 아래에서 다시 등장
    }
  }

  static const _colors = [
    Color(0x994D96FF), Color(0x996BCB77), Color(0x99FF922B),
    Color(0x99CC5DE8), Color(0x9920C997), Color(0x99FFD93D),
  ];

  static const _shapes = [
    [(0,0),(1,0),(2,0)],
    [(0,0),(1,0),(1,1)],
    [(0,0),(0,1),(1,0),(1,1)],
    [(0,0),(0,1),(0,2),(1,1)],
    [(0,1),(1,0),(1,1)],
  ];
}

class _BgPainter extends CustomPainter {
  final List<_Block> blocks;
  _BgPainter(this.blocks);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in blocks) {
      final x = b.x * size.width;
      final y = b.y * size.height;
      final cs = b.size;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.rotation);

      final paint = Paint()..color = b.color;
      for (final cell in b.shape) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              cell.$2 * cs - (b.shape.length * cs / 2),
              cell.$1 * cs - cs,
              cs - 2,
              cs - 2,
            ),
            Radius.circular(cs * 0.2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => true;
}
