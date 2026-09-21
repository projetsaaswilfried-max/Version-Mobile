class CompatibilityTraits {
  const CompatibilityTraits({
    this.confession,
    this.spiritualEngagement,
    this.values = const [],
    this.hobbies = const [],
    this.country,
    this.acceptedCountries = const [],
    this.age,
    this.acceptedAgeMin,
    this.acceptedAgeMax,
    this.maritalStatus,
    this.acceptedMarital = const [],
  });

  final String? confession;
  final String? spiritualEngagement;
  final List<String> values;
  final List<String> hobbies;
  final String? country;
  final List<String> acceptedCountries;
  final int? age;
  final int? acceptedAgeMin;
  final int? acceptedAgeMax;
  final String? maritalStatus;
  final List<String> acceptedMarital;
}
