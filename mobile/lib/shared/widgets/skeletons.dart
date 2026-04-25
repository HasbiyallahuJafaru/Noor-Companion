/// Pre-composed skeleton layouts used as loading placeholders.
/// Each skeleton mirrors the real screen's layout so the transition
/// from loading → content feels smooth rather than jarring.
library;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'shimmer_box.dart';

// ── Home screen skeleton ───────────────────────────────────────────────────

class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          ShimmerBox(width: 140, height: 14, radius: 6),
          const SizedBox(height: 8),
          ShimmerBox(width: 200, height: 28, radius: 8),
          const SizedBox(height: 16),
          // Prayer banner
          ShimmerBox(width: double.infinity, height: 44, radius: AppRadius.md),
          const SizedBox(height: 24),
          // Streak circle
          Center(
            child: ShimmerBox(width: 168, height: 168, isCircle: true),
          ),
          const SizedBox(height: 24),
          ShimmerBox(width: 100, height: 16, radius: 6),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ShimmerBox(
              width: double.infinity,
              height: 72,
              radius: AppRadius.lg,
            ),
          )),
        ],
      ),
    );
  }
}

// ── Therapist card skeleton ────────────────────────────────────────────────

class TherapistCardSkeleton extends StatelessWidget {
  const TherapistCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ShimmerBox(width: 56, height: 56, isCircle: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 140, height: 15, radius: 6),
                const SizedBox(height: 8),
                ShimmerBox(width: 100, height: 22, radius: AppRadius.sm),
                const SizedBox(height: 8),
                ShimmerBox(width: 80, height: 12, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full therapists list loading state — two sections with 3 cards each.
class TherapistsScreenSkeleton extends StatelessWidget {
  const TherapistsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 160, height: 28, radius: 8),
          const SizedBox(height: 8),
          ShimmerBox(width: 220, height: 14, radius: 6),
          const SizedBox(height: 20),
          ShimmerBox(width: double.infinity, height: 44, radius: AppRadius.md),
          const SizedBox(height: 28),
          ShimmerBox(width: 100, height: 14, radius: 6),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TherapistCardSkeleton(),
          )),
        ],
      ),
    );
  }
}

// ── Progress screen skeleton ───────────────────────────────────────────────

class ProgressScreenSkeleton extends StatelessWidget {
  const ProgressScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 120, height: 28, radius: 8),
          const SizedBox(height: 24),
          // Streak summary card
          ShimmerBox(
            width: double.infinity,
            height: 88,
            radius: AppRadius.lg,
          ),
          const SizedBox(height: 16),
          // Weekly chart
          ShimmerBox(
            width: double.infinity,
            height: 168,
            radius: AppRadius.lg,
          ),
          const SizedBox(height: 28),
          ShimmerBox(width: 100, height: 16, radius: 6),
          const SizedBox(height: 20),
          // Badge grid — 5 circles
          Wrap(
            spacing: 16,
            runSpacing: 20,
            children: List.generate(
              5,
              (_) => const ShimmerBox(width: 72, height: 88, radius: 8),
            ),
          ),
        ],
      ),
    );
  }
}
