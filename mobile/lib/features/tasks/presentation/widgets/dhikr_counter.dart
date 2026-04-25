/// Dhikr counter widget — a large tappable circle showing current count
/// and target. Each tap increments the count, fires HapticFeedback.mediumImpact,
/// and plays a subtle press animation. On completion the button turns gold,
/// shows a checkmark, and fires a success chime (Phase 2 audio).
/// A reset button appears below on completion.
/// Caller provides [onComplete] to react when the target is reached.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/dhikr_item.dart';
import '../providers/dhikr_counter_provider.dart';

class DhikrCounter extends StatefulWidget {
  const DhikrCounter({
    super.key,
    required this.item,
    this.onComplete,
  });

  final DhikrItem item;

  /// Called once when the count reaches the target. Not called on reset.
  final VoidCallback? onComplete;

  @override
  State<DhikrCounter> createState() => _DhikrCounterState();
}

class _DhikrCounterState extends State<DhikrCounter>
    with SingleTickerProviderStateMixin {
  late DhikrCounterState _counter;
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _counter = DhikrCounterState(item: widget.item);

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurveTween(curve: Curves.easeIn).animate(_pressController),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_counter.isComplete) return;

    // Press-down animation
    await _pressController.forward();
    await _pressController.reverse();

    HapticFeedback.mediumImpact();

    final next = _counter.increment();
    setState(() => _counter = next);

    if (next.isComplete) {
      HapticFeedback.heavyImpact();
      widget.onComplete?.call();
      // Audio chime wired in Phase 2
    }
  }

  void _onReset() {
    HapticFeedback.lightImpact();
    setState(() => _counter = _counter.reset());
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _counter.isComplete;
    final activeColor = isComplete ? AppColors.brandGold : AppColors.brandTeal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: isComplete
              ? '${widget.item.translation} complete'
              : 'Tap to count ${widget.item.translation}. '
                  '${_counter.count} of ${_counter.item.targetCount}',
          button: true,
          child: ScaleTransition(
            scale: _pressScale,
            child: GestureDetector(
              onTap: _onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isComplete ? AppColors.goldLight : AppColors.tealLight,
                  border: Border.all(color: activeColor, width: 3),
                  boxShadow: isComplete ? AppShadows.goldGlow : AppShadows.md,
                ),
                child: isComplete
                    ? Icon(Icons.check_rounded, color: activeColor, size: 48)
                    : _CountDisplay(
                        count: _counter.count,
                        target: _counter.item.targetCount,
                        color: activeColor,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedOpacity(
          opacity: isComplete ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: isComplete
              ? TextButton.icon(
                  onPressed: _onReset,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                  ),
                )
              : const SizedBox(height: 36),
        ),
      ],
    );
  }
}

class _CountDisplay extends StatelessWidget {
  const _CountDisplay({
    required this.count,
    required this.target,
    required this.color,
  });

  final int count;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$count',
          style: AppTextStyles.displayLarge.copyWith(
            color: color,
            fontSize: 44,
          ),
        ),
        Text(
          '/ $target',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
