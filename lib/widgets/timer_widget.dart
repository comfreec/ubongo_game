import 'package:flutter/material.dart';

class TimerWidget extends StatelessWidget {
  final int seconds;

  const TimerWidget({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final isUrgent = seconds <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red : Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '⏱ $seconds',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
