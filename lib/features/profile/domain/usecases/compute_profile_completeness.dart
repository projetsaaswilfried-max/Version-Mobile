import '../entities/profile_completeness.dart';
import '../entities/profile_field_keys.dart';
import '../entities/profile_fields_snapshot.dart';

class ComputeProfileCompleteness {
  const ComputeProfileCompleteness();

  ProfileCompleteness call(ProfileFieldsSnapshot s) {
    final missing = <String>[];
    if (!s.hasGender) missing.add(ProfileFieldKeys.gender);
    if (!s.hasBirthDate) missing.add(ProfileFieldKeys.birthDate);
    if (!s.hasCountry) missing.add(ProfileFieldKeys.country);
    if (!s.hasPrimaryPhoto) missing.add(ProfileFieldKeys.photo);
    if (!s.hasFaithConfession) missing.add(ProfileFieldKeys.confession);
    if (!s.hasWhyMarriage) missing.add(ProfileFieldKeys.whyMarriage);
    if (!s.hasMaritalStatus) missing.add(ProfileFieldKeys.maritalStatus);
    if (!s.hasHobbies) missing.add(ProfileFieldKeys.hobbies);
    return ProfileCompleteness(
      isComplete: missing.isEmpty,
      missingKeys: missing,
    );
  }
}
