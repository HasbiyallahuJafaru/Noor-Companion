/// Riverpod providers for the home screen.
/// streak_provider: days-clean counter (stub — real logic in Phase 3).
/// tasks_provider: today's task list with completion state.
/// Both use stub data until the backend is wired in Phase 2/3.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/task_model.dart';

// ── Streak ────────────────────────────────────────────────────────────────────

/// Stub streak provider — returns hardcoded days-clean count.
/// Replaced with a real API-backed notifier in Phase 3.
final streakProvider = Provider<int>((_) => 7);

/// Whether today's streak milestone should show a gold glow.
/// Milestones: 7, 30, 90, 180, 365 days.
final isMilestoneDayProvider = Provider<bool>((ref) {
  const milestones = {7, 30, 90, 180, 365};
  return milestones.contains(ref.watch(streakProvider));
});

// ── Tasks ─────────────────────────────────────────────────────────────────────

/// Notifier that owns today's task list and completion toggles.
class TasksNotifier extends Notifier<List<TaskModel>> {
  @override
  List<TaskModel> build() => _stubTasks;

  /// Toggles the completed state of a task by its [id].
  void toggleComplete(String id) {
    state = [
      for (final task in state)
        if (task.id == id) task.copyWith(isCompleted: !task.isCompleted)
        else task,
    ];
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, List<TaskModel>>(
  TasksNotifier.new,
);

/// Derived provider — true when all tasks for today are done.
final allTasksDoneProvider = Provider<bool>((ref) {
  final tasks = ref.watch(tasksProvider);
  return tasks.isNotEmpty && tasks.every((t) => t.isCompleted);
});

// ── Stub data ─────────────────────────────────────────────────────────────────

const _stubTasks = [
  TaskModel(
    id: 'tasbih',
    label: 'Morning Tasbih',
    category: TaskCategory.dhikr,
    estimatedMinutes: 5,
    targetCount: 99,
  ),
  TaskModel(
    id: 'quran',
    label: 'Read 1 page of Quran',
    category: TaskCategory.quran,
    estimatedMinutes: 10,
  ),
  TaskModel(
    id: 'wudu',
    label: 'Make wudu',
    category: TaskCategory.physical,
    estimatedMinutes: 3,
  ),
];
