import '../../domain/entities/my_profile.dart';
import '../../domain/entities/my_profile_photo.dart';

class MyProfileRaw {
  const MyProfileRaw({
    this.firstName,
    this.lastName,
    this.gender,
    this.birthDate,
    this.country,
    this.city,
    this.profession,
    this.bio,
    this.photoVerificationStatus,
    this.willingToRelocate = false,
    this.relocateAvailable = false,
    this.isPremium = false,
    this.photos = const [],
    this.denomination = '',
    this.whyMarriage = '',
    this.maritalStatusDb,
  });

  final String? firstName;
  final String? lastName;
  final String? gender;
  final String? birthDate;
  final String? country;
  final String? city;
  final String? profession;
  final String? bio;
  final String? photoVerificationStatus;
  final bool willingToRelocate;
  final bool relocateAvailable;
  final bool isPremium;
  final List<MyProfilePhoto> photos;
  final String denomination;
  final String whyMarriage;
  final String? maritalStatusDb;
}

abstract class MyProfileRemoteDataSource {
  Future<MyProfileRaw> fetchRaw();

  Future<void> save(MyProfile profile, {required bool savePhotos});
}
