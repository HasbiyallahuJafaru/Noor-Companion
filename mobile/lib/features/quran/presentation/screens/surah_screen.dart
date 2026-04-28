/// Surah detail screen — verse-by-verse display with Arabic + translation
/// and a full-surah audio player at the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/content/domain/models/verse_model.dart';
import '../../../../features/dhikr/presentation/providers/dhikr_audio_provider.dart';
import '../providers/quran_provider.dart';

class SurahScreen extends ConsumerStatefulWidget {
  const SurahScreen({super.key, required this.surahNumber});

  final int surahNumber;

  @override
  ConsumerState<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends ConsumerState<SurahScreen> {
  DhikrAudioController? _audioController;

  @override
  void dispose() {
    _audioController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahDetailProvider(widget.surahNumber));

    return surahAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (surah) {
        _audioController ??= surah.audioUrl != null
            ? DhikrAudioController(surah.audioUrl!)
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(surah.nameEnglish),
                Text(
                  '${surah.verseCount} verses · ${surah.revelationType}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  surah.nameArabic,
                  style: AppTextStyles.arabicLarge.copyWith(fontSize: 22),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Bismillah (all surahs except Al-Fatiha and At-Tawbah) ────
              if (surah.surahNumber != 1 && surah.surahNumber != 9)
                _BismillahBanner(),
              // ── Verse list ───────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, 16, 16,
                      _audioController != null ? 96 : 32),
                  physics: const BouncingScrollPhysics(),
                  itemCount: surah.verses?.length ?? 0,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    color: AppColors.border,
                  ),
                  itemBuilder: (_, i) =>
                      _VerseTile(verse: surah.verses![i]),
                ),
              ),
              // ── Audio player ─────────────────────────────────────────────
              if (_audioController != null)
                _BottomAudioPlayer(controller: _audioController!),
            ],
          ),
        );
      },
    );
  }
}

// ── Bismillah banner ──────────────────────────────────────────────────────────

class _BismillahBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.tealLight,
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textAlign: TextAlign.center,
        style: AppTextStyles.arabicLarge.copyWith(
          fontSize: 22,
          color: AppColors.brandTeal,
        ),
      ),
    );
  }
}

// ── Verse tile ────────────────────────────────────────────────────────────────

class _VerseTile extends StatelessWidget {
  const _VerseTile({required this.verse});

  final VerseModel verse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Verse number badge + Arabic
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.tealLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${verse.number}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brandTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  verse.arabicText,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.arabicLarge.copyWith(fontSize: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Translation
          Text(
            verse.translation,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom audio player ───────────────────────────────────────────────────────

class _BottomAudioPlayer extends StatelessWidget {
  const _BottomAudioPlayer({required this.controller});

  final DhikrAudioController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, _) {
        final s = controller.state;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _PlayButton(
                  isLoading: s.isLoading,
                  isPlaying: s.isPlaying,
                  hasError: s.hasError,
                  onTap: controller.togglePlayback,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: s.hasError
                      ? Text(s.error!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error))
                      : _ProgressBar(
                          position: s.position, duration: s.duration),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatDuration(s.position),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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
        width: 44,
        height: 44,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.brandTeal),
      );
    }
    return GestureDetector(
      onTap: hasError ? null : onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.brandTeal,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 24,
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
