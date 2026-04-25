/// Domain model for a task assigned during crisis intervention.
/// One task is randomly selected from the pool and shown on screen 3.
/// Timed tasks (walks) carry a [durationSeconds] for the in-screen timer.
library;

import 'dart:math';

enum InterventionTaskType { verbal, physical, timed }

class InterventionTask {
  const InterventionTask({
    required this.id,
    required this.label,
    required this.instruction,
    required this.type,
    this.durationSeconds,
  });

  final String id;
  final String label;
  final String instruction;
  final InterventionTaskType type;

  /// Only set for [InterventionTaskType.timed] tasks.
  final int? durationSeconds;
}

/// Full task pool drawn from DESIGN_BRIEF.md.
const _kTaskPool = [
  InterventionTask(
    id: 'tasbih',
    label: 'Morning Tasbih',
    instruction:
        'Say SubḥānAllāh 33 times, then Alḥamdulillāh 33 times, then Allāhu Akbar 34 times.',
    type: InterventionTaskType.verbal,
  ),
  InterventionTask(
    id: 'istighfar',
    label: 'Istighfar × 100',
    instruction:
        'Say Astaghfirullāh 100 times. Let each word land in your heart.',
    type: InterventionTaskType.verbal,
  ),
  InterventionTask(
    id: 'salawat',
    label: 'Salawat × 100',
    instruction:
        'Say Allāhumma ṣalli ʿalā Muḥammad 100 times.',
    type: InterventionTaskType.verbal,
  ),
  InterventionTask(
    id: 'ikhlas',
    label: 'Recite Sūrat Al-Ikhlāṣ × 3',
    instruction:
        'Recite Qul Huwa Allāhu Aḥad three times with presence.',
    type: InterventionTaskType.verbal,
  ),
  InterventionTask(
    id: 'ayat_kursi',
    label: 'Recite Āyat Al-Kursī',
    instruction:
        'Recite Āyat Al-Kursī once, slowly and with understanding.',
    type: InterventionTaskType.verbal,
  ),
  InterventionTask(
    id: 'wudu',
    label: 'Make wudu',
    instruction:
        'Go to the tap and make a full, unhurried wudu. Feel the water.',
    type: InterventionTaskType.physical,
  ),
  InterventionTask(
    id: 'nafl',
    label: 'Pray 2 rakʿāt nafl',
    instruction:
        'Stand up and pray two voluntary rakʿāt. Focus on each movement.',
    type: InterventionTaskType.physical,
  ),
  InterventionTask(
    id: 'quran',
    label: 'Read 1 page of Quran',
    instruction: 'Open the Quran and read one page slowly.',
    type: InterventionTaskType.physical,
  ),
  InterventionTask(
    id: 'water',
    label: 'Drink a glass of water',
    instruction:
        'Go to the kitchen. Fill a full glass of cold water and drink it slowly.',
    type: InterventionTaskType.physical,
  ),
  InterventionTask(
    id: 'cold_water',
    label: 'Splash cold water on your face',
    instruction:
        'Go to a sink. Splash cold water on your face three times.',
    type: InterventionTaskType.physical,
  ),
  InterventionTask(
    id: 'walk',
    label: '5-minute walk',
    instruction:
        'Step outside or find a corridor. Walk for 5 minutes — no phone.',
    type: InterventionTaskType.timed,
    durationSeconds: 300,
  ),
];

/// Returns a randomly selected task from the pool.
InterventionTask pickRandomTask() {
  return _kTaskPool[Random().nextInt(_kTaskPool.length)];
}
