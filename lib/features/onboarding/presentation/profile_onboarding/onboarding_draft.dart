import 'package:equatable/equatable.dart';

enum OnboardingGender { woman, man, other }

enum OnboardingMaritalStatus { single, divorced, widowed }

class OnboardingDraft extends Equatable {
  const OnboardingDraft({
    this.gender,
    this.birthDate,
    this.country,
    this.photoPaths = const [],
    this.selfiePath,
    this.faithConfession = '',
    this.maritalStatus,
    this.heightCm,
    this.whyMarriage = '',
    this.bio = '',
  });

  final OnboardingGender? gender;
  final DateTime? birthDate;
  final String? country;
  final List<String> photoPaths;
  final String? selfiePath;
  final String faithConfession;
  final OnboardingMaritalStatus? maritalStatus;
  final int? heightCm;
  final String whyMarriage;
  final String bio;

  static const maxFreePhotos = 2;

  OnboardingDraft copyWith({
    OnboardingGender? gender,
    DateTime? birthDate,
    String? country,
    List<String>? photoPaths,
    String? selfiePath,
    bool clearSelfie = false,
    String? faithConfession,
    OnboardingMaritalStatus? maritalStatus,
    int? heightCm,
    bool clearHeight = false,
    String? whyMarriage,
    String? bio,
  }) {
    return OnboardingDraft(
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      country: country ?? this.country,
      photoPaths: photoPaths ?? this.photoPaths,
      selfiePath: clearSelfie ? null : (selfiePath ?? this.selfiePath),
      faithConfession: faithConfession ?? this.faithConfession,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
      whyMarriage: whyMarriage ?? this.whyMarriage,
      bio: bio ?? this.bio,
    );
  }

  @override
  List<Object?> get props => [
    gender,
    birthDate,
    country,
    photoPaths,
    selfiePath,
    faithConfession,
    maritalStatus,
    heightCm,
    whyMarriage,
    bio,
  ];
}

class OnboardingValidators {
  const OnboardingValidators._();

  static bool isAtLeast18(DateTime birthDate, {DateTime? now}) {
    final today = now ?? DateTime.now();
    var age = today.year - birthDate.year;
    final hadBirthday =
        today.month > birthDate.month ||
        (today.month == birthDate.month && today.day >= birthDate.day);
    if (!hadBirthday) age -= 1;
    return age >= 18;
  }

  /// Returns fieldErrors for the step, empty if valid.
  static Map<String, String> errorsForStep(int step, OnboardingDraft draft) {
    switch (step) {
      case 0:
        final errors = <String, String>{};
        if (draft.gender == null) {
          errors['gender'] = 'Choisis ton genre.';
        }
        if (draft.birthDate == null) {
          errors['birthDate'] = 'Indique ta date de naissance.';
        } else if (!isAtLeast18(draft.birthDate!)) {
          errors['birthDate'] = 'Tu dois avoir au moins 18 ans.';
        }
        if (draft.country == null || draft.country!.trim().isEmpty) {
          errors['country'] = 'Indique ton pays.';
        }
        return errors;
      case 1:
        if (draft.photoPaths.isEmpty) {
          return {'photos': 'Ajoute au moins une photo.'};
        }
        return {};
      case 2:
        if (draft.selfiePath == null || draft.selfiePath!.isEmpty) {
          return {'selfie': 'Prends un selfie avec la caméra.'};
        }
        return {};
      case 3:
        final errors = <String, String>{};
        if (draft.faithConfession.trim().isEmpty) {
          errors['faithConfession'] = 'Décris ta confession.';
        }
        if (draft.maritalStatus == null) {
          errors['maritalStatus'] = 'Indique ta situation.';
        }
        return errors;
      case 4:
        if (draft.whyMarriage.trim().isEmpty) {
          return {
            'whyMarriage': 'Explique pourquoi tu cherches le mariage.',
          };
        }
        return {};
      default:
        return {};
    }
  }

  static bool canGoNext(int step, OnboardingDraft draft) =>
      errorsForStep(step, draft).isEmpty;
}
