import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A full-screen animated "underwater" backdrop: a blue depth gradient with
/// slow-drifting caustic light ribbons that shimmer like sun through water.
///
/// Wrap the whole app with this (via [MaterialApp.builder]) and keep scaffolds
/// transparent so it shows through every screen.
class WaterBackground extends StatefulWidget {
  const WaterBackground({super.key, required this.child});
  final Widget child;

  @override
  State<WaterBackground> createState() => _WaterBackgroundState();
}

class _WaterBackgroundState extends State<WaterBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? const [Color(0xFF001A33), Color(0xFF003049), Color(0xFF00404D)]
        : const [Color(0xFFEAF6FD), Color(0xFFC4E6F7), Color(0xFF9AD2EC)];

    // White light ribbons read as sun caustics; brighter in light mode where
    // they glow gently, faint in dark mode so they don't wash out content.
    final highlight =
        Colors.white.withValues(alpha: isDark ? 0.10 : 0.35);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradient,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => CustomPaint(
                painter: _CausticsPainter(_controller.value, highlight),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _CausticsPainter extends CustomPainter {
  _CausticsPainter(this.t, this.highlight);

  /// Animation phase, 0..1.
  final double t;
  final Color highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    const bands = 4;
    for (var i = 0; i < bands; i++) {
      final phase = t * 2 * math.pi + i * 1.7;
      final yBase = size.height * (0.12 + 0.22 * i);
      final amp = 20.0 + i * 10;
      final waves = 1.5 + i * 0.5;

      final path = Path()..moveTo(0, yBase);
      for (double x = 0; x <= size.width; x += 14) {
        final y =
            yBase + math.sin((x / size.width) * 2 * math.pi * waves + phase) * amp;
        path.lineTo(x, y);
      }

      paint
        ..color = highlight.withValues(alpha: highlight.a * (1 - i * 0.18))
        ..strokeWidth = 16.0 - i * 2.5;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CausticsPainter old) =>
      old.t != t || old.highlight != highlight;
}
