import 'package:equatable/equatable.dart';

class DiscoverProfileDetail extends Equatable {
  const DiscoverProfileDetail({
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
    this.photoUrls = const [],
    this.isVerified = false,
    this.score = 0,
    this.confession,
    this.spiritualEngagement,
    this.whyMarriage,
    this.verse,
    this.testimony,
    this.values = const [],
    this.hobbies = const [],
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
  final List<String> photoUrls;
  final bool isVerified;
  final int score;
  final String? confession;
  final String? spiritualEngagement;
  final String? whyMarriage;
  final String? verse;
  final String? testimony;
  final List<String> values;
  final List<String> hobbies;
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
    photoUrls,
    isVerified,
    score,
    confession,
    spiritualEngagement,
    whyMarriage,
    verse,
    testimony,
    values,
    hobbies,
    qualities,
  ];
}
