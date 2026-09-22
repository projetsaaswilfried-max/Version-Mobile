import '../entities/onboarding_draft.dart';

String? genderToDb(OnboardingGender gender) {
  switch (gender) {
    case OnboardingGender.man:
      return 'MALE';
    case OnboardingGender.woman:
      return 'FEMALE';
    case OnboardingGender.other:
      return null;
  }
}

String maritalToDb(OnboardingMaritalStatus status) {
  switch (status) {
    case OnboardingMaritalStatus.single:
      return 'SINGLE_NO_CHILDREN';
    case OnboardingMaritalStatus.singleWithChildren:
      return 'SINGLE_WITH_CHILDREN';
    case OnboardingMaritalStatus.divorced:
      return 'DIVORCED';
    case OnboardingMaritalStatus.widowed:
      return 'WIDOWED';
  }
}

/// Colonnes live `profiles` (sondage REST 2026-09-17) :
/// confession = `church_denomination` (pas `denomination`).
const profilesChurchDenominationColumn = 'church_denomination';

const profilesOnboardingSelect =
    'gender, birth_date, country, $profilesChurchDenominationColumn, why_marriage';

String profilesDateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

Map<String, Object> onboardingProfilesPatch({
  required String genderDb,
  required DateTime birthDate,
  required String country,
  required String faithConfession,
  required String maritalStatusDb,
  required String whyMarriage,
  required bool onboardingCompleted,
  List<String> hobbies = const [],
}) {
  return {
    'gender': genderDb,
    'birth_date': profilesDateOnly(birthDate),
    'country': country,
    profilesChurchDenominationColumn: faithConfession,
    'marital_status': maritalStatusDb,
    'why_marriage': whyMarriage,
    'onboarding_completed': onboardingCompleted,
    'hobbies': hobbies,
  };
}
