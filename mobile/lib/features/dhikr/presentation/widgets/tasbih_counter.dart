/// Large tappable tasbih counter widget.
/// Shows the current count, a progress arc toward the target, and vibrates
/// on each tap (light) and on reaching the target count (medium).
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TasbihCounter extends StatefulWidget {
  const TasbihCounter({
    super.key,
    required this.count,
    required this.target,
    required this.onTap,
    required this.onReset,
  });

  final int count;
  final int target;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  State<TasbihCounter> createState() => _TasbihCounterState();
}

class _TasbihCounterState extends State<TasbihCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    _pulseController.forward().then((_) => _pulseController.reverse());
    widget.onTap();

    final isComplete = widget.count + 1 >= widget.target;
    if (isComplete) {
      HapticFeedback.mediumImpact();
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) Vibration.vibrate(duration: 200, amplitude: 128);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        (widget.count / widget.target).clamp(0.0, 1.0);
    final isComplete = widget.count >= widget.target;

    return Column(
      children: [
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, child) => Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            ),
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _CounterArcPainter(
                      progress: progress,
                      isComplete: isComplete,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.count}',
                        style: AppTextStyles.displayLarge.copyWith(
                          fontSize: 56,
                          color: isComplete
                              ? AppColors.brandGold
                              : AppColors.brandTeal,
                        ),
                      ),
                      Text(
                        'of ${widget.target}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: widget.onReset,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Reset'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _CounterArcPainter extends CustomPainter {
  const _CounterArcPainter({
    required this.progress,
    required this.isComplete,
  });

  final double progress;
  final bool isComplete;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = isComplete ? AppColors.brandGold : AppColors.brandTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_CounterArcPainter old) =>
      old.progress != progress || old.isComplete != isComplete;
}
