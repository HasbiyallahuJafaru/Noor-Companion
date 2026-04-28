/// Dua detail screen — full Arabic text, transliteration, translation,
/// optional audio player, source reference, and bookmark toggle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/arabic_text_block.dart';
import '../../../content/domain/models/dua_model.dart';
import '../../../dhikr/presentation/providers/dhikr_audio_provider.dart';
import '../../../streaks/presentation/providers/streak_provider.dart';
import '../../../streaks/presentation/widgets/milestone_overlay.dart';
import '../providers/duas_provider.dart';

class DuaDetailScreen extends ConsumerStatefulWidget {
  const DuaDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends ConsumerState<DuaDetailScreen> {
  DhikrAudioController? _audioController;
  bool _completed = false;

  @override
  void dispose() {
    _audioController?.dispose();
    super.dispose();
  }

  DuaModel? _findItem(List<DuaModel> items) {
    try {
      return items.firstWhere((i) => i.id == widget.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _recordProgress(DuaModel item) async {
    if (_completed) return;
    setState(() => _completed = true);
    try {
      final streak = await recordDuaProgress(ref, item.id);
      ref.read(streakNotifierProvider.notifier).applyProgressResult(streak);
      if (mounted && streak.isMilestone) {
        await MilestoneOverlay.show(context, days: streak.currentStreak);
      }
    } catch (_) {
      if (mounted) setState(() => _completed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(duasListProvider);

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
}

// ── Main scaffold ─────────────────────────────────────────────────────────────

class _DetailScaffold extends ConsumerWidget {
  const _DetailScaffold({
    required this.item,
    required this.audioController,
    required this.completed,
    required this.onComplete,
  });

  final DuaModel item;
  final DhikrAudioController? audioController;
  final bool completed;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(
      duaBookmarkProvider.select((s) => s.contains(item.id)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(item.title),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isBookmarked ? AppColors.brandTeal : null,
            ),
            onPressed: () =>
                ref.read(duaBookmarkProvider.notifier).toggle(item.id),
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Occasion chip ────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: _OccasionChip(occasion: item.occasion),
              ),
              const SizedBox(height: 20),
              // ── Arabic text block ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.sm,
                ),
                child: ArabicTextBlock(
                  arabic: item.arabicText,
                  transliteration: item.transliteration,
                  translation: item.translation,
                ),
              ),
              // ── Audio player ─────────────────────────────────────────────
              if (audioController != null) ...[
                const SizedBox(height: 24),
                _AudioPlayer(controller: audioController!),
              ],
              // ── Source reference ─────────────────────────────────────────
              if (item.source != null) ...[
                const SizedBox(height: 20),
                _SourceRow(source: item.source!),
              ],
              // ── Tags ─────────────────────────────────────────────────────
              if (item.tags.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags
                      .map((t) => _TagChip(tag: t))
                      .toList(),
                ),
              ],
              // ── Mark as read ─────────────────────────────────────────────
              const SizedBox(height: 32),
              _MarkReadButton(completed: completed, onTap: onComplete),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Occasion chip ─────────────────────────────────────────────────────────────

class _OccasionChip extends StatelessWidget {
  const _OccasionChip({required this.occasion});

  final String occasion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brandTeal.withAlpha(51)),
      ),
      child: Text(
        occasion[0].toUpperCase() + occasion.substring(1),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.brandTeal,
          fontWeight: FontWeight.w600,
        ),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.error))
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
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.brandTeal),
      );
    }
    return GestureDetector(
      onTap: hasError ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.brandTeal,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 22,
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

// ── Source reference ──────────────────────────────────────────────────────────

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.auto_stories_rounded,
            size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            source,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        tag,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Mark as read button ───────────────────────────────────────────────────────

class _MarkReadButton extends StatelessWidget {
  const _MarkReadButton({required this.completed, required this.onTap});

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
            Text(
              'Recorded — Barakallahu feek',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.brandTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.brandTeal,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: Text('Mark as Read', style: AppTextStyles.button),
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
