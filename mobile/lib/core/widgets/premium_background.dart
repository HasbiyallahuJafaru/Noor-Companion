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
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    // Respect the OS reduce-motion setting — paint a static frame instead
    // of the ambient 12s loop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _ctrl.value = 0.5;
      } else {
        _ctrl.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates the animating canvas from the widget tree,
    // preventing the blobs from triggering repaints on scroll content above.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => CustomPaint(
          painter: _BlobPainter(_anim.value),
          child: const SizedBox.expand(),
        ),
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

    // Ink blob — top-left, drifts gently (soft navy depth)
    _drawBlob(
      canvas,
      center: Offset(
        w * (-0.05 + 0.08 * t),
        h * (0.08 + 0.06 * t),
      ),
      radiusX: w * 0.55,
      radiusY: h * 0.30,
      rotation: 0.3 + 0.15 * t,
      color: AppColors.ink.withValues(alpha: 0.05),
    );

    // Gold blob — bottom-right whisper (streak warmth)
    _drawBlob(
      canvas,
      center: Offset(
        w * (0.95 - 0.06 * t),
        h * (0.88 - 0.05 * t),
      ),
      radiusX: w * 0.50,
      radiusY: h * 0.28,
      rotation: -0.4 + 0.1 * t,
      color: AppColors.brandGold.withValues(alpha: 0.07),
    );

    // Accent teal — mid-right
    _drawBlob(
      canvas,
      center: Offset(
        w * (1.0 - 0.04 * t),
        h * (0.42 + 0.06 * t),
      ),
      radiusX: w * 0.35,
      radiusY: h * 0.20,
      rotation: 1.0 + 0.2 * t,
      color: AppColors.brandTeal.withValues(alpha: 0.07),
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
