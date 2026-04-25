/// Teal-tinted shimmer loading placeholder.
/// Used as skeleton content while data is being fetched.
/// Respects MediaQuery.disableAnimations — shows a static teal-light
/// box instead of animating when reduced motion is on.
library;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius,
    this.isCircle = false,
  });

  final double width;
  final double height;
  final double? radius;
  final bool isCircle;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.of(context).disableAnimations) {
        _ctrl.repeat();
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
    final shape = widget.isCircle
        ? BoxShape.circle
        : BoxShape.rectangle;

    final borderRadius = widget.isCircle
        ? null
        : BorderRadius.circular(widget.radius ?? AppRadius.sm);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final useAnimation = !MediaQuery.of(context).disableAnimations;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: borderRadius,
            gradient: useAnimation
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [
                      AppColors.tealLight,
                      AppColors.tealXLight,
                      AppColors.tealLight,
                    ],
                    stops: [
                      (_shimmer.value - 0.3).clamp(0.0, 1.0),
                      _shimmer.value.clamp(0.0, 1.0),
                      (_shimmer.value + 0.3).clamp(0.0, 1.0),
                    ],
                  )
                : null,
            color: useAnimation ? null : AppColors.tealLight,
          ),
        );
      },
    );
  }
}
