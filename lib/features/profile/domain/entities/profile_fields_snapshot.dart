import 'package:equatable/equatable.dart';

import '../../../onboarding/domain/entities/onboarding_draft.dart';

class ProfileFieldsSnapshot extends Equatable {
  const ProfileFieldsSnapshot({
    required this.hasGender,
    required this.hasBirthDate,
    required this.hasCountry,
    required this.hasPrimaryPhoto,
    required this.hasFaithConfession,
    required this.hasWhyMarriage,
    required this.hasMaritalStatus,
    required this.hasHobbies,
    this.genderDb,
    this.birthDate,
    this.country,
    this.firstName,
    this.lastName,
    this.photoVerificationStatus,
    this.primaryPhotoUrl,
  });

  final bool hasGender;
  final bool hasBirthDate;
  final bool hasCountry;
  final bool hasPrimaryPhoto;
  final bool hasFaithConfession;
  final bool hasWhyMarriage;
  final bool hasMaritalStatus;
  final bool hasHobbies;
  final String? genderDb;
  final DateTime? birthDate;
  final String? country;
  final String? firstName;
  final String? lastName;
  final String? photoVerificationStatus;
  final String? primaryPhotoUrl;

  bool get essentialsLocked {
    if (!hasGender || !hasBirthDate || !hasCountry) return false;
    return _genderFromDb(genderDb) != null;
  }

  OnboardingDraft hydrateDraft(OnboardingDraft current) {
    if (!essentialsLocked) return current;
    return current.copyWith(
      gender: _genderFromDb(genderDb) ?? current.gender,
      birthDate: birthDate ?? current.birthDate,
      country: country ?? current.country,
    );
  }

  static OnboardingGender? _genderFromDb(String? value) {
    switch (value?.toUpperCase()) {
      case 'MALE':
        return OnboardingGender.man;
      case 'FEMALE':
        return OnboardingGender.woman;
      default:
        return null;
    }
  }

  @override
  List<Object?> get props => [
    hasGender,
    hasBirthDate,
    hasCountry,
    hasPrimaryPhoto,
    hasFaithConfession,
    hasWhyMarriage,
    hasMaritalStatus,
    hasHobbies,
    genderDb,
    birthDate,
    country,
    firstName,
    lastName,
    photoVerificationStatus,
    primaryPhotoUrl,
  ];
}
