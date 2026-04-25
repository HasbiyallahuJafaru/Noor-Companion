/// Intervention screen 3 — physical or verbal task.
/// One task is randomly selected from the pool on screen load.
/// Timed tasks show a countdown timer; all others show a large "I did it" button.
/// The random pick is fixed for the lifetime of this screen — no re-rolls on rebuild.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/intervention_task.dart';

class InterventionTaskScreen extends StatefulWidget {
  const InterventionTaskScreen({super.key});

  @override
  State<InterventionTaskScreen> createState() => _InterventionTaskScreenState();
}

class _InterventionTaskScreenState extends State<InterventionTaskScreen> {
  /// Task is picked once on init and held for the screen's lifetime.
  late final InterventionTask _task;

  @override
  void initState() {
    super.initState();
    _task = pickRandomTask();
  }

  void _onDone() {
    HapticFeedback.lightImpact();
    context.go(AppRoutes.interventionAffirm);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your task',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.brandTeal,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_task.label, style: AppTextStyles.headingLarge),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _task.instruction,
                          style: AppTextStyles.body,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_task.type == InterventionTaskType.timed)
                        _TimedTaskBody(
                          durationSeconds: _task.durationSeconds!,
                          onDone: _onDone,
                        )
                      else
                        _DoneButton(onDone: _onDone),
                    ],
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

/// Large "I did it" button for non-timed tasks.
class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onDone,
      child: const Text('I did it'),
    );
  }
}

/// Countdown timer for timed tasks (e.g. 5-minute walk).
/// Shows MM:SS, a linear progress bar, and a Done button that only
/// activates once the timer reaches zero.
class _TimedTaskBody extends StatefulWidget {
  const _TimedTaskBody({
    required this.durationSeconds,
    required this.onDone,
  });

  final int durationSeconds;
  final VoidCallback onDone;

  @override
  State<_TimedTaskBody> createState() => _TimedTaskBodyState();
}

class _TimedTaskBodyState extends State<_TimedTaskBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timer;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          HapticFeedback.heavyImpact();
          setState(() => _isFinished = true);
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  String get _timeRemaining {
    final remaining =
        (widget.durationSeconds * (1 - _timer.value)).round();
    final m = remaining ~/ 60;
    final s = remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _timer,
      builder: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              _timeRemaining,
              style: AppTextStyles.displayLarge.copyWith(
                color: _isFinished
                    ? AppColors.brandTeal
                    : AppColors.textPrimary,
                fontSize: 52,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _timer.value,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.brandTeal),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isFinished ? widget.onDone : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandTeal,
              disabledBackgroundColor: AppColors.border,
            ),
            child: Text(_isFinished ? 'I did it' : 'Keep going…'),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
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
            '3 of 4',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
