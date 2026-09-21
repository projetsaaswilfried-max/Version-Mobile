import 'package:agapeo/features/onboarding/domain/entities/onboarding_draft.dart';
import 'package:agapeo/features/profile/domain/entities/profile_field_keys.dart';
import 'package:agapeo/features/profile/domain/entities/profile_fields_snapshot.dart';
import 'package:agapeo/features/profile/domain/usecases/compute_profile_completeness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compute = ComputeProfileCompleteness();

  test('complete when all fields present', () {
    final r = compute(
      const ProfileFieldsSnapshot(
        hasGender: true,
        hasBirthDate: true,
        hasCountry: true,
        hasPrimaryPhoto: true,
        hasFaithConfession: true,
        hasWhyMarriage: true,
      ),
    );
    expect(r.isComplete, isTrue);
    expect(r.missingKeys, isEmpty);
  });

  test('lists each missing key', () {
    final r = compute(
      const ProfileFieldsSnapshot(
        hasGender: false,
        hasBirthDate: true,
        hasCountry: false,
        hasPrimaryPhoto: false,
        hasFaithConfession: false,
        hasWhyMarriage: true,
      ),
    );
    expect(r.isComplete, isFalse);
    expect(r.missingKeys, [
      ProfileFieldKeys.gender,
      ProfileFieldKeys.country,
      ProfileFieldKeys.photo,
      ProfileFieldKeys.confession,
    ]);
  });

  test('hydrateDraft fills locked essentials', () {
    final snapshot = ProfileFieldsSnapshot(
      hasGender: true,
      hasBirthDate: true,
      hasCountry: true,
      hasPrimaryPhoto: false,
      hasFaithConfession: false,
      hasWhyMarriage: false,
      genderDb: 'FEMALE',
      birthDate: DateTime(1992, 3, 4),
      country: 'France',
    );
    expect(snapshot.essentialsLocked, isTrue);
    final draft = snapshot.hydrateDraft(const OnboardingDraft());
    expect(draft.gender, OnboardingGender.woman);
    expect(draft.country, 'France');
    expect(draft.birthDate, DateTime(1992, 3, 4));
  });

  test('unknown gender does not lock essentials', () {
    const snapshot = ProfileFieldsSnapshot(
      hasGender: true,
      hasBirthDate: true,
      hasCountry: true,
      hasPrimaryPhoto: false,
      hasFaithConfession: false,
      hasWhyMarriage: false,
      genderDb: 'OTHER',
      country: 'France',
    );
    expect(snapshot.essentialsLocked, isFalse);
    expect(snapshot.hydrateDraft(const OnboardingDraft()).gender, isNull);
  });
}
