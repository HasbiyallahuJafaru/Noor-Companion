/// Domain model for a daily recovery task.
/// Tasks are drawn from the task pool defined in DESIGN_BRIEF.md.
/// They are assigned daily and can be verbal (dhikr) or physical.
library;

/// Broad category used to assign an appropriate icon and timing behaviour.
enum TaskCategory {
  dhikr,
  physical,
  quran,
  prayer,
}

/// A single daily task assigned to the user.
class TaskModel {
  const TaskModel({
    required this.id,
    required this.label,
    required this.category,
    required this.estimatedMinutes,
    this.isCompleted = false,
    this.targetCount,
  });

  final String id;

  /// Short display label shown on the task card.
  final String label;

  final TaskCategory category;

  /// Rough duration shown as a badge on the card.
  final int estimatedMinutes;

  final bool isCompleted;

  /// For counted tasks (dhikr), the total repetitions required.
  final int? targetCount;

  TaskModel copyWith({bool? isCompleted}) {
    return TaskModel(
      id: id,
      label: label,
      category: category,
      estimatedMinutes: estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      targetCount: targetCount,
    );
  }
}
