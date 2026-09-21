import 'package:equatable/equatable.dart';

import 'my_profile_photo.dart';

class MyProfile extends Equatable {
  const MyProfile({
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.profession,
    required this.bio,
    required this.isVerified,
    this.willingToRelocate = false,
    this.relocateAvailable = false,
    this.genderLabel,
    this.birthDateLabel,
    this.country,
    this.isPremium = false,
    this.photos = const [],
    this.denomination = '',
    this.whyMarriage = '',
    this.maritalStatusDb,
  });

  final String firstName;
  final String lastName;
  final String city;
  final String profession;
  final String bio;
  final bool willingToRelocate;
  final bool relocateAvailable;
  final String? genderLabel;
  final String? birthDateLabel;
  final String? country;
  final bool isVerified;
  final bool isPremium;
  final List<MyProfilePhoto> photos;
  final String denomination;
  final String whyMarriage;
  final String? maritalStatusDb;

  MyProfile copyWith({
    String? firstName,
    String? lastName,
    String? city,
    String? profession,
    String? bio,
    bool? willingToRelocate,
    bool? relocateAvailable,
    String? genderLabel,
    String? birthDateLabel,
    String? country,
    bool? isVerified,
    bool? isPremium,
    List<MyProfilePhoto>? photos,
    String? denomination,
    String? whyMarriage,
    String? maritalStatusDb,
    bool clearMaritalStatusDb = false,
  }) {
    return MyProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      city: city ?? this.city,
      profession: profession ?? this.profession,
      bio: bio ?? this.bio,
      willingToRelocate: willingToRelocate ?? this.willingToRelocate,
      relocateAvailable: relocateAvailable ?? this.relocateAvailable,
      genderLabel: genderLabel ?? this.genderLabel,
      birthDateLabel: birthDateLabel ?? this.birthDateLabel,
      country: country ?? this.country,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      photos: photos ?? this.photos,
      denomination: denomination ?? this.denomination,
      whyMarriage: whyMarriage ?? this.whyMarriage,
      maritalStatusDb: clearMaritalStatusDb
          ? null
          : (maritalStatusDb ?? this.maritalStatusDb),
    );
  }

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    city,
    profession,
    bio,
    willingToRelocate,
    relocateAvailable,
    genderLabel,
    birthDateLabel,
    country,
    isVerified,
    isPremium,
    photos,
    denomination,
    whyMarriage,
    maritalStatusDb,
  ];
}
