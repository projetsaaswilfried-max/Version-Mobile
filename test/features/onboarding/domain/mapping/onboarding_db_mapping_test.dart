import 'package:agapeo/features/onboarding/domain/entities/onboarding_draft.dart';
import 'package:agapeo/features/onboarding/domain/mapping/onboarding_db_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps man/woman and marital single', () {
    expect(genderToDb(OnboardingGender.man), 'MALE');
    expect(genderToDb(OnboardingGender.woman), 'FEMALE');
    expect(genderToDb(OnboardingGender.other), isNull);
    expect(maritalToDb(OnboardingMaritalStatus.single), 'SINGLE_NO_CHILDREN');
    expect(
      maritalToDb(OnboardingMaritalStatus.singleWithChildren),
      'SINGLE_WITH_CHILDREN',
    );
    expect(maritalToDb(OnboardingMaritalStatus.divorced), 'DIVORCED');
    expect(maritalToDb(OnboardingMaritalStatus.widowed), 'WIDOWED');
  });

  test('profiles patch writes church_denomination not denomination', () {
    final row = onboardingProfilesPatch(
      genderDb: 'FEMALE',
      birthDate: DateTime(1995, 1, 2),
      country: 'France',
      faithConfession: 'Évangélique',
      maritalStatusDb: 'SINGLE_NO_CHILDREN',
      whyMarriage: 'Alliance',
      onboardingCompleted: true,
    );
    expect(row.containsKey('denomination'), isFalse);
    expect(row['church_denomination'], 'Évangélique');
    expect(row['why_marriage'], 'Alliance');
    expect(row['birth_date'], '1995-01-02');
    expect(row['onboarding_completed'], isTrue);
  });
}
