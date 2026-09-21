import 'package:equatable/equatable.dart';

import '../scoring/compatibility_traits.dart';

class DiscoverProfile extends Equatable {
  const DiscoverProfile({
    required this.id,
    required this.displayName,
    this.age,
    this.city,
    this.photoUrl,
    this.isVerified = false,
    this.score = 0,
    this.gender,
    this.isStaff = false,
    this.isMatched = false,
    this.isComplete = true,
    this.traits = const CompatibilityTraits(),
    this.ageLabel,
    this.isLiked = false,
    this.isFavorited = false,
  });

  final String id;
  final String displayName;
  final int? age;
  final String? city;
  final String? photoUrl;
  final bool isVerified;
  final int score;
  final String? gender;
  final bool isStaff;
  final bool isMatched;
  final bool isComplete;
  final CompatibilityTraits traits;
  final String? ageLabel;
  final bool isLiked;
  final bool isFavorited;

  DiscoverProfile copyWith({
    String? displayName,
    int? age,
    bool clearAge = false,
    String? city,
    bool clearCity = false,
    String? photoUrl,
    bool? isVerified,
    int? score,
    String? gender,
    bool? isStaff,
    bool? isMatched,
    bool? isComplete,
    CompatibilityTraits? traits,
    String? ageLabel,
    bool clearAgeLabel = false,
    bool? isLiked,
    bool? isFavorited,
  }) {
    return DiscoverProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      age: clearAge ? null : (age ?? this.age),
      city: clearCity ? null : (city ?? this.city),
      photoUrl: photoUrl ?? this.photoUrl,
      isVerified: isVerified ?? this.isVerified,
      score: score ?? this.score,
      gender: gender ?? this.gender,
      isStaff: isStaff ?? this.isStaff,
      isMatched: isMatched ?? this.isMatched,
      isComplete: isComplete ?? this.isComplete,
      traits: traits ?? this.traits,
      ageLabel: clearAgeLabel ? null : (ageLabel ?? this.ageLabel),
      isLiked: isLiked ?? this.isLiked,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    age,
    city,
    photoUrl,
    isVerified,
    score,
    gender,
    isStaff,
    isMatched,
    isComplete,
    traits,
    ageLabel,
    isLiked,
    isFavorited,
  ];
}
