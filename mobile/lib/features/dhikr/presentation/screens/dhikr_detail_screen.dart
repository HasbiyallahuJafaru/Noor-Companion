/// Dhikr detail screen — shows Arabic text, transliteration, translation,
/// an audio player, and the tasbih counter. Progress is recorded on completion.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/arabic_text_block.dart';
import '../../../content/domain/models/dhikr_model.dart';
import '../providers/dhikr_audio_provider.dart';
import '../providers/dhikr_provider.dart';
import '../widgets/tasbih_counter.dart';
import '../../../streaks/presentation/providers/streak_provider.dart';
import '../../../streaks/presentation/widgets/milestone_overlay.dart';

class DhikrDetailScreen extends ConsumerStatefulWidget {
  const DhikrDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<DhikrDetailScreen> createState() => _DhikrDetailScreenState();
}

class _DhikrDetailScreenState extends ConsumerState<DhikrDetailScreen> {
  DhikrAudioController? _audioController;
  bool _completed = false;

  @override
  void dispose() {
    _audioController?.dispose();
    super.dispose();
  }

  DhikrModel? _findItem(List<DhikrModel> items) {
    try {
      return items.firstWhere((i) => i.id == widget.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(dhikrListProvider);

    return listAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (items) {
        final item = _findItem(items);
        if (item == null) return const _ErrorScaffold(message: 'Not found.');

        _audioController ??= item.audioUrl != null
            ? DhikrAudioController(item.audioUrl!)
            : null;

        return _DetailScaffold(
          item: item,
          audioController: _audioController,
          completed: _completed,
          onComplete: () => _recordProgress(item),
        );
      },
    );
  }

  Future<void> _recordProgress(DhikrModel item) async {
    if (_completed) return;
    setState(() => _completed = true);
    try {
      final streak = await recordDhikrProgress(ref, item.id);
      ref.read(streakNotifierProvider.notifier).applyProgressResult(streak);
      if (mounted && streak.isMilestone) {
        await MilestoneOverlay.show(context, days: streak.currentStreak);
      }
    } catch (_) {
      if (mounted) setState(() => _completed = false);
    }
  }
}

// ── Main scaffold ─────────────────────────────────────────────────────────────

class _DetailScaffold extends ConsumerWidget {
  const _DetailScaffold({
    required this.item,
    required this.audioController,
    required this.completed,
    required this.onComplete,
  });

  final DhikrModel item;
  final DhikrAudioController? audioController;
  final bool completed;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(dhikrCounterProvider(item.id));
    final isAtTarget = counter >= item.targetCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(item.title),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ArabicSection(item: item),
              const SizedBox(height: 32),
              if (audioController != null) ...[
                _AudioPlayer(controller: audioController!),
                const SizedBox(height: 32),
              ],
              Center(
                child: TasbihCounter(
                  count: counter,
                  target: item.targetCount,
                  onTap: () =>
                      ref.read(dhikrCounterProvider(item.id).notifier).tap(),
                  onReset: () =>
                      ref.read(dhikrCounterProvider(item.id).notifier).reset(),
                ),
              ),
              const SizedBox(height: 32),
              _CompleteButton(
                isAtTarget: isAtTarget,
                completed: completed,
                onTap: onComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Arabic text section ───────────────────────────────────────────────────────

class _ArabicSection extends StatelessWidget {
  const _ArabicSection({required this.item});

  final DhikrModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ArabicTextBlock(
            arabic: item.arabicText,
            transliteration: item.transliteration,
            translation: item.translation,
          ),
        ],
      ),
    );
  }
}

// ── Audio player ──────────────────────────────────────────────────────────────

class _AudioPlayer extends StatelessWidget {
  const _AudioPlayer({required this.controller});

  final DhikrAudioController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        final s = controller.state;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _PlayButton(
                isLoading: s.isLoading,
                isPlaying: s.isPlaying,
                hasError: s.hasError,
                onTap: controller.togglePlayback,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: s.hasError
                    ? Text(s.error!,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.error))
                    : _ProgressBar(
                        position: s.position, duration: s.duration),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isLoading,
    required this.isPlaying,
    required this.hasError,
    required this.onTap,
  });

  final bool isLoading;
  final bool isPlaying;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 40, height: 40,
        child: CircularProgressIndicator(
          strokeWidth: 2, color: AppColors.brandTeal,
        ),
      );
    }
    return GestureDetector(
      onTap: hasError ? null : onTap,
      child: Container(
        width: 40, height: 40,
        decoration: const BoxDecoration(
          color: AppColors.brandTeal, shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white, size: 22,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.position, required this.duration});

  final Duration position;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds;
    final progress = total > 0 ? position.inMilliseconds / total : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: AppColors.border,
        valueColor:
            const AlwaysStoppedAnimation<Color>(AppColors.brandTeal),
        minHeight: 4,
      ),
    );
  }
}

// ── Complete button ───────────────────────────────────────────────────────────

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({
    required this.isAtTarget,
    required this.completed,
    required this.onTap,
  });

  final bool isAtTarget;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (completed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.tealLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.brandTeal, size: 20),
            const SizedBox(width: 8),
            Text('Recorded — Barakallahu feek',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: isAtTarget ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isAtTarget ? AppColors.brandTeal : AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: Text(
          isAtTarget ? 'Mark Complete' : 'Complete the tasbih to record',
          style: AppTextStyles.button.copyWith(
            color: isAtTarget ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Loading / error scaffolds ─────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(message)),
    );
  }
}
