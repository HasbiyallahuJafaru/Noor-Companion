/// Riverpod providers for the home screen.
/// All data derives from the authenticated user or existing content providers.
/// Streak reads from the UserModel returned by GET /users/me.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../content/data/content_repository.dart';
import '../../../content/domain/models/dhikr_model.dart';

// ── User identity ─────────────────────────────────────────────────────────────

/// The authenticated user's first name. Returns empty string when loading.
final currentUserFirstNameProvider = Provider<String>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is AuthAuthenticated) return auth.user.firstName;
  return '';
});

// ── Streak ────────────────────────────────────────────────────────────────────

/// Current streak count from the authenticated user's profile.
/// The UserModel includes streak data from GET /users/me.
final currentStreakProvider = Provider<int>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is AuthAuthenticated) {
    return auth.user.streak?.currentStreak ?? 0;
  }
  return 0;
});

/// True on milestone days: 7, 14, 30, 100 (per FEATURES.md).
final isMilestoneDayProvider = Provider<bool>((ref) {
  const milestones = {7, 30, 90, 180, 365};
  return milestones.contains(ref.watch(currentStreakProvider));
});

// ── Time-of-day tag ───────────────────────────────────────────────────────────

/// Returns 'morning' before Dhuhr (12:00), 'evening' after Asr (15:30),
/// and 'general' in between. Used to filter the home screen content rows.
final timeOfDayTagProvider = Provider<String>((_) {
  final hour = DateTime.now().hour;
  final minute = DateTime.now().minute;
  final totalMinutes = hour * 60 + minute;
  if (totalMinutes < 720) return 'morning';   // before 12:00
  if (totalMinutes >= 930) return 'evening';  // after 15:30
  return 'general';
});

// ── Featured dhikr ────────────────────────────────────────────────────────────

/// The first dhikr item matching the current time-of-day tag.
/// Shown as the daily highlight card on the home screen.
final featuredDhikrProvider = StreamProvider<DhikrModel?>((ref) async* {
  final tag = ref.watch(timeOfDayTagProvider);
  final repo = ref.watch(contentRepositoryProvider);

  await for (final items in repo.watchDhikr(tag: tag)) {
    yield items.isNotEmpty ? items.first : null;
  }
});

/// Morning adhkar list — shown in the home screen horizontal row.
final morningDhikrProvider = StreamProvider<List<DhikrModel>>((ref) {
  return ref.watch(contentRepositoryProvider).watchDhikr(tag: 'morning');
});

/// Evening adhkar list — shown in the home screen horizontal row.
final eveningDhikrProvider = StreamProvider<List<DhikrModel>>((ref) {
  return ref.watch(contentRepositoryProvider).watchDhikr(tag: 'evening');
});
