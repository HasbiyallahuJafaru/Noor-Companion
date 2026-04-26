/// Streak data returned by POST /api/v1/content/:id/progress.
library;

class StreakModel {
  const StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDays,
    this.lastEngagedAt,
  });

  final int currentStreak;
  final int longestStreak;
  final int totalDays;
  final DateTime? lastEngagedAt;

  factory StreakModel.fromJson(Map<String, dynamic> json) => StreakModel(
        currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
        totalDays: (json['totalDays'] as num?)?.toInt() ?? 0,
        lastEngagedAt: json['lastEngagedAt'] != null
            ? DateTime.tryParse(json['lastEngagedAt'] as String)
            : null,
      );

  /// True when this streak count is a milestone worth celebrating.
  bool get isMilestone => const {7, 14, 30, 100}.contains(currentStreak);
}
