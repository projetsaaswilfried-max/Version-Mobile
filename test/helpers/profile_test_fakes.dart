import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/features/profile/domain/entities/my_profile.dart';
import 'package:agapeo/features/profile/domain/entities/profile_fields_snapshot.dart';
import 'package:agapeo/features/profile/domain/repositories/my_profile_repository.dart';
import 'package:agapeo/features/profile/domain/repositories/profile_fields_repository.dart';

class FakeProfileFieldsRepository implements ProfileFieldsRepository {
  FakeProfileFieldsRepository({
    this.result = const Err(ServerFailure('unset')),
  });

  Result<ProfileFieldsSnapshot> result;
  int fetchCalls = 0;

  @override
  Future<Result<ProfileFieldsSnapshot>> fetchFields() async {
    fetchCalls++;
    return result;
  }
}

ProfileFieldsSnapshot fakeProfileFieldsSnapshot({
  String? firstName = 'Léa',
  String? lastName = 'Martin',
  String? photoVerificationStatus = 'VERIFIED',
  String? primaryPhotoUrl,
  bool hasGender = true,
  bool hasBirthDate = true,
  bool hasCountry = true,
  bool? hasPrimaryPhoto,
  bool hasFaithConfession = true,
  bool hasWhyMarriage = true,
  bool hasMaritalStatus = true,
  bool hasHobbies = true,
}) {
  return ProfileFieldsSnapshot(
    hasGender: hasGender,
    hasBirthDate: hasBirthDate,
    hasCountry: hasCountry,
    hasPrimaryPhoto: hasPrimaryPhoto ?? primaryPhotoUrl != null,
    hasFaithConfession: hasFaithConfession,
    hasWhyMarriage: hasWhyMarriage,
    hasMaritalStatus: hasMaritalStatus,
    hasHobbies: hasHobbies,
    firstName: firstName,
    lastName: lastName,
    photoVerificationStatus: photoVerificationStatus,
    primaryPhotoUrl: primaryPhotoUrl,
  );
}

class FakeMyProfileRepository implements MyProfileRepository {
  FakeMyProfileRepository({
    this.fetchResult = const Err(ServerFailure('unset')),
    this.saveResult = const Ok(null),
  });

  Result<MyProfile> fetchResult;
  Result<void> saveResult;
  int fetchCalls = 0;
  int saveCalls = 0;
  bool? lastSavePhotos;
  MyProfile? lastSavedProfile;

  @override
  Future<Result<MyProfile>> fetchMine() async {
    fetchCalls++;
    return fetchResult;
  }

  @override
  Future<Result<void>> save(
    MyProfile profile, {
    required bool savePhotos,
  }) async {
    saveCalls++;
    lastSavePhotos = savePhotos;
    lastSavedProfile = profile;
    return saveResult;
  }
}

MyProfile fakeMyProfile({
  String firstName = 'Léa',
  String lastName = 'Martin',
  String bio = 'Hello',
  bool isVerified = false,
  bool relocateAvailable = true,
  bool isPremium = false,
  String denomination = 'Évangélique',
  String whyMarriage = 'Alliance',
  String? maritalStatusDb = 'SINGLE_NO_CHILDREN',
}) {
  return MyProfile(
    firstName: firstName,
    lastName: lastName,
    city: 'Paris',
    profession: 'Dev',
    bio: bio,
    isVerified: isVerified,
    isPremium: isPremium,
    relocateAvailable: relocateAvailable,
    genderLabel: 'Femme',
    birthDateLabel: '04/03/1992',
    country: 'France',
    denomination: denomination,
    whyMarriage: whyMarriage,
    maritalStatusDb: maritalStatusDb,
  );
}
