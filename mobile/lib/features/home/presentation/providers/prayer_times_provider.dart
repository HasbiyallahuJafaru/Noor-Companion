/// Prayer times state management.
/// Requests device GPS, fetches prayer times from the backend, and caches in
/// Hive. When permission is denied the state signals the banner to show an
/// "Enable location" prompt — city-search requires the geocoding package which
/// is not yet in the project and is deferred to a future sprint.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../features/content/data/content_cache.dart';
import '../../../../features/content/data/islamic_repository.dart';
import '../../../../features/content/domain/models/prayer_times_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class PrayerTimesState {
  const PrayerTimesState();
}

class PrayerTimesLoading extends PrayerTimesState {
  const PrayerTimesLoading();
}

/// Prayer times loaded. [isCached] is true when served from Hive.
class PrayerTimesLoaded extends PrayerTimesState {
  const PrayerTimesLoaded(this.times, {this.isCached = false});
  final PrayerTimesModel times;
  final bool isCached;
}

/// Location permission was denied. Banner shows "Enable location" prompt.
class PrayerTimesLocationDenied extends PrayerTimesState {
  const PrayerTimesLocationDenied();
}

class PrayerTimesError extends PrayerTimesState {
  const PrayerTimesError(this.message, {this.cached});
  final String message;

  /// Last known prayer times served alongside the error message.
  final PrayerTimesModel? cached;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PrayerTimesNotifier extends AsyncNotifier<PrayerTimesState> {
  @override
  Future<PrayerTimesState> build() => _loadFromLocation();

  /// Requests location permission then fetches prayer times from the backend.
  Future<PrayerTimesState> _loadFromLocation() async {
    final cached = getCachedPrayerTimes();

    try {
      final permission = await _resolvePermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const PrayerTimesLocationDenied();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      return await _fetch(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      if (cached != null) {
        return PrayerTimesError('Could not update times.', cached: cached);
      }
      return const PrayerTimesLocationDenied();
    }
  }

  /// Opens app settings so the user can grant location permission, then retries.
  Future<void> openSettingsAndRetry() async {
    await Geolocator.openAppSettings();
    state = const AsyncLoading();
    state = AsyncData(await _loadFromLocation());
  }

  /// Retries a failed fetch without prompting settings.
  Future<void> retry() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadFromLocation());
  }

  Future<PrayerTimesState> _fetch({
    required double lat,
    required double lng,
  }) async {
    try {
      final repo = ref.read(islamicRepositoryProvider);
      final times = await repo.getPrayerTimes(lat: lat, lng: lng);
      await savePrayerTimes(times);
      return PrayerTimesLoaded(times);
    } catch (_) {
      final cached = getCachedPrayerTimes();
      if (cached != null) {
        return PrayerTimesError('Using cached times.', cached: cached);
      }
      rethrow;
    }
  }

  /// Checks existing permission and requests it if not yet determined.
  Future<LocationPermission> _resolvePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }
}

final prayerTimesProvider =
    AsyncNotifierProvider<PrayerTimesNotifier, PrayerTimesState>(
  PrayerTimesNotifier.new,
);

// ── Countdown ─────────────────────────────────────────────────────────────────

/// Emits seconds remaining until the next prayer, updated every 60 seconds.
/// Yields null when prayer times are not yet loaded.
final nextPrayerCountdownProvider = StreamProvider<int?>((ref) async* {
  final prayerAsync = ref.watch(prayerTimesProvider);
  final prayerState = prayerAsync.asData?.value;

  PrayerTimesModel? times;
  if (prayerState is PrayerTimesLoaded) {
    times = prayerState.times;
  } else if (prayerState is PrayerTimesError) {
    times = prayerState.cached;
  }

  if (times == null) {
    yield null;
    return;
  }

  yield _secondsUntilNextPrayer(times);

  await for (final _ in Stream.periodic(const Duration(minutes: 1))) {
    yield _secondsUntilNextPrayer(times);
  }
});

int _secondsUntilNextPrayer(PrayerTimesModel times) {
  final now = DateTime.now();
  final nextName = times.nextPrayerName(now);
  final nextTimeStr =
      times.prayers.firstWhere((p) => p.name == nextName).time;
  final parts = nextTimeStr.split(':');
  if (parts.length < 2) return 0;
  final prayerDt = DateTime(
    now.year, now.month, now.day,
    int.parse(parts[0]), int.parse(parts[1]),
  );
  final target = prayerDt.isBefore(now)
      ? prayerDt.add(const Duration(days: 1))
      : prayerDt;
  return target.difference(now).inSeconds.clamp(0, 86400);
}
