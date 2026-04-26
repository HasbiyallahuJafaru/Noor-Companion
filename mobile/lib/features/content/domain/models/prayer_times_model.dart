/// Prayer times for a single day at a given location.
/// Returned by GET /api/v1/islamic/prayer-times.
library;

class PrayerTimesModel {
  const PrayerTimesModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
  });

  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  /// ISO date string, e.g. "2026-04-25".
  final String date;

  /// Returns the five canonical prayer names with their times in order.
  List<({String name, String time})> get prayers => [
        (name: 'Fajr', time: fajr),
        (name: 'Dhuhr', time: dhuhr),
        (name: 'Asr', time: asr),
        (name: 'Maghrib', time: maghrib),
        (name: 'Isha', time: isha),
      ];

  /// Returns the name of the next prayer relative to [now].
  /// Falls back to "Fajr" (tomorrow) when all prayers have passed.
  String nextPrayerName(DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;
    for (final p in prayers) {
      final parts = p.time.split(':');
      if (parts.length < 2) continue;
      final pMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (pMinutes > currentMinutes) return p.name;
    }
    return 'Fajr';
  }

  /// Returns the time string for the next prayer.
  String nextPrayerTime(DateTime now) {
    final name = nextPrayerName(now);
    return prayers.firstWhere((p) => p.name == name,
        orElse: () => prayers.first).time;
  }

  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>? ?? json;
    return PrayerTimesModel(
      fajr: _strip(timings['Fajr'] as String? ?? ''),
      sunrise: _strip(timings['Sunrise'] as String? ?? ''),
      dhuhr: _strip(timings['Dhuhr'] as String? ?? ''),
      asr: _strip(timings['Asr'] as String? ?? ''),
      maghrib: _strip(timings['Maghrib'] as String? ?? ''),
      isha: _strip(timings['Isha'] as String? ?? ''),
      date: json['date'] as String? ?? '',
    );
  }

  /// Aladhan returns times with " (UTC+1)" suffix — strip to "HH:MM".
  static String _strip(String raw) => raw.split(' ').first;
}
