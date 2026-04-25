/// Riverpod providers for the therapists feature.
/// Stub data used until Phase 4 wires the real backend API.
/// searchQuery filters the list client-side by name.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/therapist_model.dart';

/// Holds the current search query string entered in the therapists list.
class TherapistSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) => state = query;
}

final therapistSearchProvider =
    NotifierProvider<TherapistSearchNotifier, String>(
  TherapistSearchNotifier.new,
);

/// Full stub therapist list. Replaced with API call in Phase 4.
final therapistsProvider = Provider<List<TherapistModel>>((_) => _kStubTherapists);

/// Counsellors filtered by the current search query.
final filteredCounsellorsProvider = Provider<List<TherapistModel>>((ref) {
  final query = ref.watch(therapistSearchProvider).toLowerCase().trim();
  final all = ref.watch(therapistsProvider);
  final counsellors = all.where(
    (t) => t.specialty == TherapistSpecialty.counsellor,
  );
  if (query.isEmpty) return counsellors.toList();
  return counsellors
      .where((t) => t.name.toLowerCase().contains(query))
      .toList();
});

/// Islamic scholars filtered by the current search query.
final filteredScholarsProvider = Provider<List<TherapistModel>>((ref) {
  final query = ref.watch(therapistSearchProvider).toLowerCase().trim();
  final all = ref.watch(therapistsProvider);
  final scholars = all.where(
    (t) => t.specialty == TherapistSpecialty.islamicScholar,
  );
  if (query.isEmpty) return scholars.toList();
  return scholars
      .where((t) => t.name.toLowerCase().contains(query))
      .toList();
});

/// Looks up a single therapist by id. Returns null if not found.
final therapistByIdProvider =
    Provider.family<TherapistModel?, String>((ref, id) {
  return ref
      .watch(therapistsProvider)
      .where((t) => t.id == id)
      .firstOrNull;
});

// ── Stub data ─────────────────────────────────────────────────────────────────

const _kStubTherapists = [
  TherapistModel(
    id: 'c1',
    name: 'Dr. Amina Hassan',
    specialty: TherapistSpecialty.counsellor,
    bio:
        'Dr. Amina is a licensed clinical psychologist with 12 years of experience '
        'supporting Muslims navigating addiction and mental health. She integrates '
        'evidence-based CBT with Islamic values.',
    isAvailable: true,
    averageRating: 4.9,
    sessionCount: 214,
  ),
  TherapistModel(
    id: 'c2',
    name: 'Yusuf Al-Rasheed',
    specialty: TherapistSpecialty.counsellor,
    bio:
        'Yusuf is a certified addiction counsellor specialising in substance recovery '
        'for young Muslim men. He draws on both modern therapy and Prophetic wisdom '
        'to support long-term change.',
    isAvailable: false,
    averageRating: 4.7,
    sessionCount: 98,
  ),
  TherapistModel(
    id: 'c3',
    name: 'Fatima Nour',
    specialty: TherapistSpecialty.counsellor,
    bio:
        'Fatima holds an MSc in counselling psychology and works primarily with '
        'Muslim women. Her approach is compassionate, trauma-informed, and '
        'rooted in Islamic spirituality.',
    isAvailable: true,
    averageRating: 4.8,
    sessionCount: 157,
  ),
  TherapistModel(
    id: 's1',
    name: 'Sheikh Ibrahim Musa',
    specialty: TherapistSpecialty.islamicScholar,
    bio:
        'Sheikh Ibrahim studied for 10 years at Al-Azhar and has guided hundreds '
        'of individuals through spiritual crises. He specialises in the Islamic '
        'psychology of the nafs and the path of tawbah.',
    isAvailable: true,
    averageRating: 4.95,
    sessionCount: 312,
  ),
  TherapistModel(
    id: 's2',
    name: 'Ustadha Maryam Idris',
    specialty: TherapistSpecialty.islamicScholar,
    bio:
        'Ustadha Maryam combines traditional Islamic scholarship with a deep '
        'understanding of addiction as a spiritual and psychological struggle. '
        'She speaks Arabic, English, and Hausa.',
    isAvailable: false,
    averageRating: 4.85,
    sessionCount: 189,
  ),
  TherapistModel(
    id: 's3',
    name: 'Ustadh Khalid Umar',
    specialty: TherapistSpecialty.islamicScholar,
    bio:
        'Ustadh Khalid is known for his gentle, non-judgmental approach to guiding '
        'those struggling with addiction back to the deen. He has studied under '
        'scholars in Medina and Cape Town.',
    isAvailable: true,
    averageRating: 4.9,
    sessionCount: 265,
  ),
];
