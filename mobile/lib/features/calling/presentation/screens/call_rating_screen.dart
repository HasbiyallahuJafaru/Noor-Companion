/// Post-call rating screen — shown immediately after a call ends.
/// User taps 1–5 stars and optionally adds a comment, then submits.
/// Tapping "Skip" dismisses without submitting a rating.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/calling_provider.dart';

class CallRatingScreen extends ConsumerStatefulWidget {
  const CallRatingScreen({
    super.key,
    required this.sessionId,
    required this.therapistName,
    required this.durationSeconds,
  });

  final String sessionId;
  final String therapistName;
  final int durationSeconds;

  @override
  ConsumerState<CallRatingScreen> createState() => _CallRatingScreenState();
}

class _CallRatingScreenState extends ConsumerState<CallRatingScreen> {
  int _selectedRating = 0;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              _Header(
                therapistName: widget.therapistName,
                durationSeconds: widget.durationSeconds,
              ),
              const SizedBox(height: 40),
              _StarRow(
                selected: _selectedRating,
                onSelect: (v) => setState(() => _selectedRating = v),
              ),
              const SizedBox(height: 28),
              _CommentField(controller: _commentCtrl),
              const Spacer(),
              _SubmitButton(
                canSubmit: _selectedRating > 0 && !_isSubmitting,
                onSubmit: _submit,
              ),
              const SizedBox(height: 12),
              _SkipButton(onSkip: _close),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) return;
    setState(() => _isSubmitting = true);

    await ref.read(callingProvider.notifier).submitRating(
          widget.sessionId,
          _selectedRating,
          comment: _commentCtrl.text.trim(),
        );

    if (mounted) _close();
  }

  void _close() {
    Navigator.of(context).popUntil((route) => route.settings.name == '/home');
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.therapistName, required this.durationSeconds});

  final String therapistName;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    final mins = durationSeconds ~/ 60;
    final secs = durationSeconds % 60;
    final duration = mins > 0
        ? '$mins min ${secs}s'
        : '${secs}s';

    return Column(
      children: [
        const Icon(Icons.call_end_rounded, color: AppColors.brandTeal, size: 48),
        const SizedBox(height: 16),
        Text('Call Ended', style: AppTextStyles.headingLarge),
        const SizedBox(height: 6),
        Text(
          'Session with $therapistName · $duration',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'How was your session?',
          style: AppTextStyles.headingMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Star row ──────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  const _StarRow({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onSelect(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              star <= selected ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppColors.brandGold,
              size: 40,
            ),
          ),
        );
      }),
    );
  }
}

// ── Comment field ─────────────────────────────────────────────────────────────

class _CommentField extends StatelessWidget {
  const _CommentField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      maxLength: 500,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: 'Leave a comment (optional)…',
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.canSubmit, required this.onSubmit});

  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: canSubmit ? onSubmit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandTeal,
        minimumSize: const Size(double.infinity, 52),
        disabledBackgroundColor: AppColors.border,
      ),
      child: const Text('Submit Rating'),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onSkip,
      child: Text(
        'Skip',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
