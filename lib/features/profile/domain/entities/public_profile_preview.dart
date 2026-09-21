import 'package:equatable/equatable.dart';

import 'my_profile_photo.dart';

class PublicProfilePreview extends Equatable {
  const PublicProfilePreview({
    required this.id,
    required this.displayName,
    this.age,
    this.city,
    this.country,
    this.gender,
    this.profession,
    this.bio,
    this.heightCm,
    this.maritalStatus,
    this.isVerified = false,
    this.photos = const [],
    this.denomination,
    this.spiritualEngagement,
    this.whyMarriage,
    this.verse,
    this.testimony,
    this.values = const [],
    this.passions = const [],
    this.qualities = const [],
  });

  final String id;
  final String displayName;
  final int? age;
  final String? city;
  final String? country;
  final String? gender;
  final String? profession;
  final String? bio;
  final int? heightCm;
  final String? maritalStatus;
  final bool isVerified;
  final List<MyProfilePhoto> photos;
  final String? denomination;
  final String? spiritualEngagement;
  final String? whyMarriage;
  final String? verse;
  final String? testimony;
  final List<String> values;
  final List<String> passions;
  final List<String> qualities;

  @override
  List<Object?> get props => [
    id,
    displayName,
    age,
    city,
    country,
    gender,
    profession,
    bio,
    heightCm,
    maritalStatus,
    isVerified,
    photos,
    denomination,
    spiritualEngagement,
    whyMarriage,
    verse,
    testimony,
    values,
    passions,
    qualities,
  ];
}
