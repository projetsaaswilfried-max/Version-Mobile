import 'package:equatable/equatable.dart';

class FaithDetails extends Equatable {
  const FaithDetails({
    this.denomination = '',
    this.whyMarriage = '',
    this.spiritualEngagement = '',
    this.ministry = '',
    this.yearsConverted = '',
    this.verse = '',
    this.testimony = '',
    this.godWork = '',
    this.baptized = false,
    this.denominationAvailable = true,
    this.whyMarriageAvailable = true,
    this.spiritualEngagementAvailable = false,
    this.ministryAvailable = false,
    this.yearsConvertedAvailable = false,
    this.verseAvailable = false,
    this.testimonyAvailable = false,
    this.godWorkAvailable = false,
    this.baptizedAvailable = false,
  });

  static const maxVerse = 200;
  static const maxTestimony = 600;
  static const maxGodWork = 600;
  static const maxWhyMarriage = 1000;

  final String denomination;
  final String whyMarriage;
  final String spiritualEngagement;
  final String ministry;
  final String yearsConverted;
  final String verse;
  final String testimony;
  final String godWork;
  final bool baptized;
  final bool denominationAvailable;
  final bool whyMarriageAvailable;
  final bool spiritualEngagementAvailable;
  final bool ministryAvailable;
  final bool yearsConvertedAvailable;
  final bool verseAvailable;
  final bool testimonyAvailable;
  final bool godWorkAvailable;
  final bool baptizedAvailable;

  FaithDetails copyWith({
    String? denomination,
    String? whyMarriage,
    String? spiritualEngagement,
    String? ministry,
    String? yearsConverted,
    String? verse,
    String? testimony,
    String? godWork,
    bool? baptized,
    bool? denominationAvailable,
    bool? whyMarriageAvailable,
    bool? spiritualEngagementAvailable,
    bool? ministryAvailable,
    bool? yearsConvertedAvailable,
    bool? verseAvailable,
    bool? testimonyAvailable,
    bool? godWorkAvailable,
    bool? baptizedAvailable,
  }) {
    return FaithDetails(
      denomination: denomination ?? this.denomination,
      whyMarriage: whyMarriage ?? this.whyMarriage,
      spiritualEngagement: spiritualEngagement ?? this.spiritualEngagement,
      ministry: ministry ?? this.ministry,
      yearsConverted: yearsConverted ?? this.yearsConverted,
      verse: verse ?? this.verse,
      testimony: testimony ?? this.testimony,
      godWork: godWork ?? this.godWork,
      baptized: baptized ?? this.baptized,
      denominationAvailable:
          denominationAvailable ?? this.denominationAvailable,
      whyMarriageAvailable: whyMarriageAvailable ?? this.whyMarriageAvailable,
      spiritualEngagementAvailable:
          spiritualEngagementAvailable ?? this.spiritualEngagementAvailable,
      ministryAvailable: ministryAvailable ?? this.ministryAvailable,
      yearsConvertedAvailable:
          yearsConvertedAvailable ?? this.yearsConvertedAvailable,
      verseAvailable: verseAvailable ?? this.verseAvailable,
      testimonyAvailable: testimonyAvailable ?? this.testimonyAvailable,
      godWorkAvailable: godWorkAvailable ?? this.godWorkAvailable,
      baptizedAvailable: baptizedAvailable ?? this.baptizedAvailable,
    );
  }

  @override
  List<Object?> get props => [
    denomination,
    whyMarriage,
    spiritualEngagement,
    ministry,
    yearsConverted,
    verse,
    testimony,
    godWork,
    baptized,
    denominationAvailable,
    whyMarriageAvailable,
    spiritualEngagementAvailable,
    ministryAvailable,
    yearsConvertedAvailable,
    verseAvailable,
    testimonyAvailable,
    godWorkAvailable,
    baptizedAvailable,
  ];
}
