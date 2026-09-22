import '../entities/onboarding_draft.dart';
import '../mapping/onboarding_db_mapping.dart';

class OnboardingSubmitPayload {
  const OnboardingSubmitPayload({
    required this.genderDb,
    required this.birthDate,
    required this.country,
    required this.faithConfession,
    required this.maritalStatusDb,
    required this.whyMarriage,
    this.photoPaths = const [],
    this.hobbies = const [],
  });

  final String genderDb;
  final DateTime birthDate;
  final String country;
  final String faithConfession;
  final String maritalStatusDb;
  final String whyMarriage;
  final List<String> photoPaths;
  final List<String> hobbies;

  String? get profilePhotoPath => photoPaths.isEmpty ? null : photoPaths.first;

  /// Returns null if draft cannot be mapped (ex. gender other).
  static OnboardingSubmitPayload? tryFromDraft(OnboardingDraft draft) {
    final g = draft.gender;
    final b = draft.birthDate;
    final c = draft.country;
    final m = draft.maritalStatus;
    if (g == null || b == null || c == null || m == null) return null;
    final genderDb = genderToDb(g);
    if (genderDb == null) return null;
    return OnboardingSubmitPayload(
      genderDb: genderDb,
      birthDate: b,
      country: c,
      faithConfession: draft.faithConfession.trim(),
      maritalStatusDb: maritalToDb(m),
      whyMarriage: draft.whyMarriage.trim(),
      photoPaths: draft.photoPaths,
      hobbies: draft.hobbies,
    );
  }
}
