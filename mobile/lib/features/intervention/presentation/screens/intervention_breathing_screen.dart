/// Intervention screen 2 — guided breathing exercise.
/// Animated circle expands (inhale 4s), holds (4s), contracts (exhale 4s).
/// Runs 3 full cycles then auto-advances to screen 3.
/// Skip link top-right available throughout.
/// Animation respects MediaQuery.disableAnimations for accessibility.
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Phase durations in milliseconds.
const _kInhaleMs = 4000;
const _kHoldMs = 4000;
const _kExhaleMs = 4000;
const _kCycleMs = _kInhaleMs + _kHoldMs + _kExhaleMs;
const _kTotalCycles = 3;

enum _BreathPhase { inhale, hold, exhale }

class InterventionBreathingScreen extends StatefulWidget {
  const InterventionBreathingScreen({super.key});

  @override
  State<InterventionBreathingScreen> createState() =>
      _InterventionBreathingScreenState();
}

class _InterventionBreathingScreenState
    extends State<InterventionBreathingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  final int _cycle = 0;

  @override
  void initState() {
    super.initState();

    final totalDuration =
        Duration(milliseconds: _kCycleMs * _kTotalCycles);

    _controller = AnimationController(vsync: this, duration: totalDuration);

    // Scale oscillates 0.5 → 1.0 → 0.5 each cycle
    _scale = TweenSequence<double>([
      for (int i = 0; i < _kTotalCycles; i++) ...[
        TweenSequenceItem(
          tween: Tween(begin: 0.5, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: _kInhaleMs.toDouble(),
        ),
        TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: _kHoldMs.toDouble(),
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.5)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: _kExhaleMs.toDouble(),
        ),
      ],
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _advance();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _advance();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _advance() => context.go(AppRoutes.interventionTask);

  _BreathPhase get _currentPhase {
    final cycleProgress =
        (_controller.value * _kTotalCycles) % 1.0;
    final inhaleFraction = _kInhaleMs / _kCycleMs;
    final holdFraction = _kHoldMs / _kCycleMs;
    if (cycleProgress < inhaleFraction) return _BreathPhase.inhale;
    if (cycleProgress < inhaleFraction + holdFraction) return _BreathPhase.hold;
    return _BreathPhase.exhale;
  }

  String get _phaseLabel => switch (_currentPhase) {
        _BreathPhase.inhale => 'Inhale',
        _BreathPhase.hold => 'Hold',
        _BreathPhase.exhale => 'Exhale',
      };

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(onSkip: _advance),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BreathCircle(scale: _scale.value),
                        const SizedBox(height: 32),
                        Text(
                          _phaseLabel,
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.brandTeal,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cycle ${math.min(_cycle + 1, _kTotalCycles)} of $_kTotalCycles',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathCircle extends StatelessWidget {
  const _BreathCircle({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    const maxSize = 240.0;
    final size = maxSize * scale;

    return SizedBox(
      width: maxSize,
      height: maxSize,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.tealLight,
            border: Border.all(
              color: AppColors.brandTeal.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandTeal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
            tooltip: 'Exit crisis support',
            onPressed: () => context.go(AppRoutes.home),
          ),
          const Spacer(),
          Text(
            '2 of 4',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSkip,
            child: Text(
              'Skip',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
