import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

class ThreadVoiceWaveform extends StatelessWidget {
  const ThreadVoiceWaveform({
    super.key,
    required this.samples,
    required this.color,
  });

  final List<double> samples;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.lg,
      child: CustomPaint(
        painter: _WaveformPainter(samples: samples, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({required this.samples, required this.color});

  final List<double> samples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 3.0;
    const gap = 2.0;
    final maxBars = (size.width / (barWidth + gap)).floor().clamp(1, 48);
    final values = samples.length > maxBars
        ? samples.sublist(samples.length - maxBars)
        : samples;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    final startX = size.width - values.length * (barWidth + gap) + gap / 2;
    for (var i = 0; i < values.length; i++) {
      final height = (values[i] * size.height).clamp(
        AppSpacing.xs,
        size.height,
      );
      final x = startX + i * (barWidth + gap);
      final y = (size.height - height) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, height),
          const Radius.circular(AppRadius.sm),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.samples != samples || oldDelegate.color != color;
  }
}
