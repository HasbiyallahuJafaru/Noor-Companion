/// Full-screen celebration overlay shown when the user reaches a streak milestone.
/// Triggered by dhikr and duas detail screens after POST /content/:id/progress
/// returns a StreakModel where isMilestone is true.
///
/// Usage:
///   if (streak.isMilestone) {
///     MilestoneOverlay.show(context, days: streak.currentStreak);
///   }
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MilestoneOverlay {
  /// Shows the overlay as a full-screen dialog.
  /// Dismisses automatically after 3 seconds or on tap.
  static Future<void> show(BuildContext context, {required int days}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '_',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (ctx, animation, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      ),
      pageBuilder: (ctx, a, b) => _MilestoneOverlayContent(days: days),
    );
  }
}

class _MilestoneOverlayContent extends StatefulWidget {
  const _MilestoneOverlayContent({required this.days});

  final int days;

  @override
  State<_MilestoneOverlayContent> createState() =>
      _MilestoneOverlayContentState();
}

class _MilestoneOverlayContentState extends State<_MilestoneOverlayContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _headline {
    if (widget.days >= 100) return 'A Century of Clarity';
    if (widget.days >= 30) return 'Thirty Days Strong';
    if (widget.days >= 14) return 'Two Weeks of Light';
    return 'One Week of Clarity';
  }

  String get _subtext =>
      'SubhanAllah — ${widget.days} days of consistent remembrance. '
      'May Allah keep your heart firm.';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ScaleTransition(
              scale: _pulse,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandGold.withValues(alpha:0.35),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.brandGold.withValues(alpha:0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GoldArc(days: widget.days),
                    const SizedBox(height: 24),
                    Text(
                      _headline,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.brandGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _subtext,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Tap anywhere to continue',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a gold filled arc with the day count centred inside.
class _GoldArc extends StatelessWidget {
  const _GoldArc({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(140, 140),
            painter: _ArcPainter(days: days),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$days',
                style: AppTextStyles.displayLarge.copyWith(
                  color: AppColors.brandGold,
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'days',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandGold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.days});

  final int days;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    final track = Paint()
      ..color = AppColors.goldLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = AppColors.brandGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(centre, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.days != days;
}
