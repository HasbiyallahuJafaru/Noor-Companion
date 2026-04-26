/// Hive-backed local cache for content items, prayer times, and bookmarks.
/// Returns cached data on app start so there is no loading flash.
/// The repository updates the cache after every successful API fetch.
library;

import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/dhikr_model.dart';
import '../domain/models/dua_model.dart';
import '../domain/models/prayer_times_model.dart';
import '../domain/models/recitation_model.dart';

const _kDhikrBox = 'dhikr_cache';
const _kDuasBox = 'duas_cache';
const _kRecitationsBox = 'recitations_cache';
const _kPrayerTimesBox = 'prayer_times_cache';
const _kBookmarksBox = 'bookmarks_cache';

const _kDhikrKey = 'dhikr_list';
const _kDuasKey = 'duas_list';
const _kRecitationsKey = 'recitations_list';
const _kPrayerTimesKey = 'prayer_times';
const _kDuaBookmarksKey = 'dua_bookmarks';

/// Opens all Hive boxes required by the content cache.
/// Called once during app initialisation in main.dart before runApp.
Future<void> openContentBoxes() async {
  await Hive.openBox<dynamic>(_kDhikrBox);
  await Hive.openBox<dynamic>(_kDuasBox);
  await Hive.openBox<dynamic>(_kRecitationsBox);
  await Hive.openBox<dynamic>(_kPrayerTimesBox);
  await Hive.openBox<dynamic>(_kBookmarksBox);
}

// ── Dhikr ─────────────────────────────────────────────────────────────────────

/// Returns cached dhikr list, or empty list if the cache is cold.
List<DhikrModel> getCachedDhikr() {
  final box = Hive.box<dynamic>(_kDhikrBox);
  final raw = box.get(_kDhikrKey) as List?;
  if (raw == null) return [];
  return raw
      .map((e) => DhikrModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Persists the dhikr list to Hive.
Future<void> saveDhikr(List<DhikrModel> items) async {
  final box = Hive.box<dynamic>(_kDhikrBox);
  await box.put(_kDhikrKey, items.map((e) => e.toJson()).toList());
}

// ── Duas ──────────────────────────────────────────────────────────────────────

/// Returns cached duas list, or empty list if the cache is cold.
List<DuaModel> getCachedDuas() {
  final box = Hive.box<dynamic>(_kDuasBox);
  final raw = box.get(_kDuasKey) as List?;
  if (raw == null) return [];
  return raw
      .map((e) => DuaModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Persists the duas list to Hive.
Future<void> saveDuas(List<DuaModel> items) async {
  final box = Hive.box<dynamic>(_kDuasBox);
  await box.put(_kDuasKey, items.map((e) => e.toJson()).toList());
}

// ── Recitations ───────────────────────────────────────────────────────────────

/// Returns cached recitations list, or empty list if the cache is cold.
List<RecitationModel> getCachedRecitations() {
  final box = Hive.box<dynamic>(_kRecitationsBox);
  final raw = box.get(_kRecitationsKey) as List?;
  if (raw == null) return [];
  return raw
      .map((e) =>
          RecitationModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

/// Persists the recitations list to Hive.
Future<void> saveRecitations(List<RecitationModel> items) async {
  final box = Hive.box<dynamic>(_kRecitationsBox);
  await box.put(
      _kRecitationsKey, items.map((e) => e.toJson()).toList());
}

// ── Prayer times ──────────────────────────────────────────────────────────────

/// Returns the last successfully fetched prayer times, or null if never fetched.
PrayerTimesModel? getCachedPrayerTimes() {
  final box = Hive.box<dynamic>(_kPrayerTimesBox);
  final raw = box.get(_kPrayerTimesKey) as Map?;
  if (raw == null) return null;
  return PrayerTimesModel.fromJson(Map<String, dynamic>.from(raw));
}

/// Persists prayer times to Hive. Overwrites any previous value.
Future<void> savePrayerTimes(PrayerTimesModel times) async {
  final box = Hive.box<dynamic>(_kPrayerTimesBox);
  await box.put(_kPrayerTimesKey, {
    'Fajr': times.fajr,
    'Sunrise': times.sunrise,
    'Dhuhr': times.dhuhr,
    'Asr': times.asr,
    'Maghrib': times.maghrib,
    'Isha': times.isha,
    'date': times.date,
  });
}

// ── Dua bookmarks ─────────────────────────────────────────────────────────────

/// Returns the set of bookmarked dua IDs. Empty set if none saved.
Set<String> getBookmarkedDuaIds() {
  final box = Hive.box<dynamic>(_kBookmarksBox);
  final raw = box.get(_kDuaBookmarksKey) as List?;
  if (raw == null) return {};
  return raw.cast<String>().toSet();
}

/// Adds [duaId] to bookmarks if not present, removes it if already there.
/// Returns the new bookmark state (true = now bookmarked).
Future<bool> toggleDuaBookmark(String duaId) async {
  final box = Hive.box<dynamic>(_kBookmarksBox);
  final current = getBookmarkedDuaIds();
  final isNowBookmarked = !current.contains(duaId);
  if (isNowBookmarked) {
    current.add(duaId);
  } else {
    current.remove(duaId);
  }
  await box.put(_kDuaBookmarksKey, current.toList());
  return isNowBookmarked;
}
