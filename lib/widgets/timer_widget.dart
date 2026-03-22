import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  final int seconds;
  const TimerWidget({super.key, required this.seconds});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _shake;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -3.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 3.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 3.0, end: 0.0), weight: 25),
    ]).animate(_ctrl);
    _pulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.seconds <= 10) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TimerWidget old) {
    super.didUpdateWidget(old);
    if (widget.seconds <= 10 && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (widget.seconds > 10 && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = widget.seconds <= 10;
    final isWarning = widget.seconds <= 20;

    final color = isUrgent
        ? Colors.red
        : isWarning
            ? Colors.orange
            : Colors.black87;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: isUrgent ? Offset(_shake.value, 0) : Offset.zero,
        child: Transform.scale(
          scale: isUrgent ? _pulse.value : 1.0,
          child: child,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isUrgent
              ? [BoxShadow(color: Colors.red.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 2)]
              : [],
        ),
        child: Text(
          '⏱ ${widget.seconds}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
