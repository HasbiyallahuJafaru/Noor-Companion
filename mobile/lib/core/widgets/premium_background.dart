/// Organic fluid background — warm cream base with soft teal and gold
/// blob shapes painted asymmetrically for a premium 2026 aesthetic.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Drop this as the first child in a Stack to get the living background.
class PremiumBackground extends StatefulWidget {
  const PremiumBackground({super.key});

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => CustomPaint(
        painter: _BlobPainter(_anim.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  const _BlobPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Warm cream base
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.background,
    );

    final w = size.width;
    final h = size.height;

    // Teal blob — top-left, drifts gently
    _drawBlob(
      canvas,
      center: Offset(
        w * (-0.05 + 0.08 * t),
        h * (0.08 + 0.06 * t),
      ),
      radiusX: w * 0.55,
      radiusY: h * 0.30,
      rotation: 0.3 + 0.15 * t,
      color: AppColors.brandTeal.withValues(alpha: 0.09),
    );

    // Gold blob — bottom-right
    _drawBlob(
      canvas,
      center: Offset(
        w * (0.95 - 0.06 * t),
        h * (0.88 - 0.05 * t),
      ),
      radiusX: w * 0.50,
      radiusY: h * 0.28,
      rotation: -0.4 + 0.1 * t,
      color: AppColors.brandGold.withValues(alpha: 0.08),
    );

    // Soft teal accent — mid-right
    _drawBlob(
      canvas,
      center: Offset(
        w * (1.0 - 0.04 * t),
        h * (0.42 + 0.06 * t),
      ),
      radiusX: w * 0.35,
      radiusY: h * 0.20,
      rotation: 1.0 + 0.2 * t,
      color: AppColors.brandTeal.withValues(alpha: 0.06),
    );

    // Faint gold — top-right whisper
    _drawBlob(
      canvas,
      center: Offset(w * (0.85 + 0.03 * t), h * 0.05),
      radiusX: w * 0.30,
      radiusY: h * 0.18,
      rotation: 0.6,
      color: AppColors.brandGold.withValues(alpha: 0.06),
    );
  }

  void _drawBlob(
    Canvas canvas, {
    required Offset center,
    required double radiusX,
    required double radiusY,
    required double rotation,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;

  // ignore: unused_element
  double _lerp(double a, double b, double t) => a + (b - a) * t;
  // ignore: unused_element
  double _sin(double t) => math.sin(t * math.pi);
}
