import 'package:equatable/equatable.dart';

enum OnboardingGender { woman, man, other }

enum OnboardingMaritalStatus { single, singleWithChildren, divorced, widowed }

class OnboardingDraft extends Equatable {
  const OnboardingDraft({
    this.gender,
    this.birthDate,
    this.country,
    this.photoPaths = const [],
    this.faithConfession = '',
    this.maritalStatus,
    this.heightCm,
    this.whyMarriage = '',
    this.bio = '',
    this.hobbies = const [],
    this.selfiePath,
  });

  static const maxFreePhotos = 1;

  final OnboardingGender? gender;
  final DateTime? birthDate;
  final String? country;
  final List<String> photoPaths;
  final String faithConfession;
  final OnboardingMaritalStatus? maritalStatus;
  final int? heightCm;
  final String whyMarriage;
  final String bio;
  final List<String> hobbies;
  final String? selfiePath;

  String? get profilePhotoPath => photoPaths.isEmpty ? null : photoPaths.first;

  OnboardingDraft copyWith({
    OnboardingGender? gender,
    DateTime? birthDate,
    String? country,
    List<String>? photoPaths,
    String? profilePhotoPath,
    bool clearProfilePhoto = false,
    String? faithConfession,
    OnboardingMaritalStatus? maritalStatus,
    int? heightCm,
    bool clearHeight = false,
    String? whyMarriage,
    String? bio,
    List<String>? hobbies,
    String? selfiePath,
    bool clearSelfie = false,
  }) {
    final List<String> nextPhotos;
    if (clearProfilePhoto) {
      nextPhotos = const [];
    } else if (photoPaths != null) {
      nextPhotos = photoPaths;
    } else if (profilePhotoPath != null) {
      nextPhotos = [profilePhotoPath];
    } else {
      nextPhotos = this.photoPaths;
    }
    return OnboardingDraft(
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      country: country ?? this.country,
      photoPaths: nextPhotos,
      faithConfession: faithConfession ?? this.faithConfession,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      heightCm: clearHeight ? null : (heightCm ?? this.heightCm),
      whyMarriage: whyMarriage ?? this.whyMarriage,
      bio: bio ?? this.bio,
      hobbies: hobbies ?? this.hobbies,
      selfiePath: clearSelfie ? null : (selfiePath ?? this.selfiePath),
    );
  }

  @override
  List<Object?> get props => [
    gender,
    birthDate,
    country,
    photoPaths,
    faithConfession,
    maritalStatus,
    heightCm,
    whyMarriage,
    bio,
    hobbies,
    selfiePath,
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
        } else if (genderUnsupported(draft.gender!)) {
          errors['gender'] = 'Choisis Femme ou Homme.';
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
        final errors = <String, String>{};
        if (draft.faithConfession.trim().isEmpty) {
          errors['faithConfession'] = 'Choisis ta confession.';
        }
        if (draft.maritalStatus == null) {
          errors['maritalStatus'] = 'Indique ta situation.';
        }
        if (draft.whyMarriage.trim().isEmpty) {
          errors['whyMarriage'] = 'Explique pourquoi tu cherches le mariage.';
        }
        return errors;
      case 2:
        // Étape passions désormais obligatoire (D34) : plus de "Passer".
        final errors = <String, String>{};
        if (draft.hobbies.isEmpty) {
          errors['hobbies'] = 'Ajoute au moins un centre d\'intérêt.';
        }
        return errors;
      case 3:
        return {};
      case 4:
        // Étape selfie : jamais atteinte si la photo a été passée
        // (skipPhoto() termine directement) - obligatoire sinon, les deux
        // étapes photo + selfie doivent toujours rester collées.
        final errors = <String, String>{};
        if (draft.selfiePath == null || draft.selfiePath!.trim().isEmpty) {
          errors['selfiePath'] = 'Prends un selfie pour continuer.';
        }
        return errors;
      case 5:
        return {};
      default:
        return {};
    }
  }

  static bool genderUnsupported(OnboardingGender gender) =>
      gender == OnboardingGender.other;

  /// Étapes 0 et 1, dans l'ordre. Vide si le profil est prêt à submit/skip.
  static Map<String, String> errorsForSubmit(OnboardingDraft draft) {
    final step0 = errorsForStep(0, draft);
    if (step0.isNotEmpty) return step0;
    return errorsForStep(1, draft);
  }

  static int firstInvalidStep(OnboardingDraft draft) {
    if (errorsForStep(0, draft).isNotEmpty) return 0;
    if (errorsForStep(1, draft).isNotEmpty) return 1;
    return 2;
  }

  static bool canGoNext(int step, OnboardingDraft draft) =>
      errorsForStep(step, draft).isEmpty;
}
