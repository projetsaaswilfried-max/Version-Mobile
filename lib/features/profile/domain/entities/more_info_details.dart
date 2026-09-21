import 'package:equatable/equatable.dart';

class MoreInfoDetails extends Equatable {
  const MoreInfoDetails({
    this.qualities = const [],
    this.passions = const [],
    this.values = const [],
    this.familyVision = '',
    this.childrenWanted = '',
    this.marriageHorizon = '',
    this.likes = '',
    this.dislikes = '',
    this.qualitiesAvailable = false,
    this.passionsAvailable = false,
    this.valuesAvailable = false,
    this.familyVisionAvailable = false,
    this.childrenWantedAvailable = false,
    this.marriageHorizonAvailable = false,
    this.likesAvailable = false,
    this.dislikesAvailable = false,
  });

  static const maxQualities = 10;
  static const maxPassions = 12;
  static const maxValues = 12;
  static const maxFamilyVision = 1000;

  final List<String> qualities;
  final List<String> passions;
  final List<String> values;
  final String familyVision;
  final String childrenWanted;
  final String marriageHorizon;
  final String likes;
  final String dislikes;
  final bool qualitiesAvailable;
  final bool passionsAvailable;
  final bool valuesAvailable;
  final bool familyVisionAvailable;
  final bool childrenWantedAvailable;
  final bool marriageHorizonAvailable;
  final bool likesAvailable;
  final bool dislikesAvailable;

  MoreInfoDetails copyWith({
    List<String>? qualities,
    List<String>? passions,
    List<String>? values,
    String? familyVision,
    String? childrenWanted,
    String? marriageHorizon,
    String? likes,
    String? dislikes,
    bool? qualitiesAvailable,
    bool? passionsAvailable,
    bool? valuesAvailable,
    bool? familyVisionAvailable,
    bool? childrenWantedAvailable,
    bool? marriageHorizonAvailable,
    bool? likesAvailable,
    bool? dislikesAvailable,
  }) {
    return MoreInfoDetails(
      qualities: qualities ?? this.qualities,
      passions: passions ?? this.passions,
      values: values ?? this.values,
      familyVision: familyVision ?? this.familyVision,
      childrenWanted: childrenWanted ?? this.childrenWanted,
      marriageHorizon: marriageHorizon ?? this.marriageHorizon,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      qualitiesAvailable: qualitiesAvailable ?? this.qualitiesAvailable,
      passionsAvailable: passionsAvailable ?? this.passionsAvailable,
      valuesAvailable: valuesAvailable ?? this.valuesAvailable,
      familyVisionAvailable:
          familyVisionAvailable ?? this.familyVisionAvailable,
      childrenWantedAvailable:
          childrenWantedAvailable ?? this.childrenWantedAvailable,
      marriageHorizonAvailable:
          marriageHorizonAvailable ?? this.marriageHorizonAvailable,
      likesAvailable: likesAvailable ?? this.likesAvailable,
      dislikesAvailable: dislikesAvailable ?? this.dislikesAvailable,
    );
  }

  @override
  List<Object?> get props => [
    qualities,
    passions,
    values,
    familyVision,
    childrenWanted,
    marriageHorizon,
    likes,
    dislikes,
    qualitiesAvailable,
    passionsAvailable,
    valuesAvailable,
    familyVisionAvailable,
    childrenWantedAvailable,
    marriageHorizonAvailable,
    likesAvailable,
    dislikesAvailable,
  ];
}
