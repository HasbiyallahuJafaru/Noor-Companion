/// Simple immutable state for the dhikr counter.
/// Managed locally inside DhikrCounter (StatefulWidget) — no global provider
/// needed since counter state does not need to be shared across screens.
library;

import '../../domain/dhikr_item.dart';

class DhikrCounterState {
  const DhikrCounterState({
    required this.item,
    this.count = 0,
  });

  final DhikrItem item;
  final int count;

  /// True once count reaches item.targetCount.
  bool get isComplete => count >= item.targetCount;

  DhikrCounterState increment() => DhikrCounterState(
        item: item,
        count: count + 1,
      );

  DhikrCounterState reset() => DhikrCounterState(item: item);
}
