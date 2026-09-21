import 'compatibility_traits.dart';

int compatibilityScore({
  required CompatibilityTraits visitor,
  required CompatibilityTraits candidate,
}) {
  var score = 0;
  if (_sameNonEmpty(visitor.confession, candidate.confession)) {
    score += 12;
  }
  if (_sameNonEmpty(
    visitor.spiritualEngagement,
    candidate.spiritualEngagement,
  )) {
    score += 8;
  }
  score += _overlapScore(visitor.values, candidate.values, 20);
  score += _overlapScore(visitor.hobbies, candidate.hobbies, 15);
  score += _locationScore(visitor, candidate);
  score += _ageScore(visitor, candidate);
  score += _maritalScore(visitor, candidate);
  return score;
}

bool _sameNonEmpty(String? a, String? b) {
  if (a == null || b == null) return false;
  if (a.isEmpty || b.isEmpty) return false;
  return a == b;
}

int _overlapScore(List<String> visitor, List<String> candidate, int maxPoints) {
  final overlap = visitor.toSet().intersection(candidate.toSet()).length;
  final denom = _maxLength(visitor.length, candidate.length);
  return ((overlap / denom) * maxPoints).round();
}

int _maxLength(int a, int b) {
  final longest = a > b ? a : b;
  return longest < 1 ? 1 : longest;
}

int _locationScore(CompatibilityTraits visitor, CompatibilityTraits candidate) {
  final visitorCountry = visitor.country;
  final candidateCountry = candidate.country;
  if (visitorCountry != null &&
      visitorCountry.isNotEmpty &&
      visitorCountry == candidateCountry) {
    return 15;
  }
  final candidateAccepted =
      candidateCountry != null &&
      visitor.acceptedCountries.contains(candidateCountry);
  final visitorAccepted =
      visitorCountry != null &&
      candidate.acceptedCountries.contains(visitorCountry);
  if (candidateAccepted || visitorAccepted) return 8;
  return 0;
}

int _ageScore(CompatibilityTraits visitor, CompatibilityTraits candidate) {
  final visitorFits = _ageInRange(
    candidate.age,
    visitor.acceptedAgeMin,
    visitor.acceptedAgeMax,
  );
  final candidateFits = _ageInRange(
    visitor.age,
    candidate.acceptedAgeMin,
    candidate.acceptedAgeMax,
  );
  if (visitorFits && candidateFits) return 10;
  if (visitorFits || candidateFits) return 5;
  return 0;
}

bool _ageInRange(int? age, int? min, int? max) {
  if (age == null) return false;
  if (min == null && max == null) return false;
  if (min != null && age < min) return false;
  if (max != null && age > max) return false;
  return true;
}

int _maritalScore(CompatibilityTraits visitor, CompatibilityTraits candidate) {
  final visitorAccepts = _accepts(
    candidate.maritalStatus,
    visitor.acceptedMarital,
  );
  final candidateAccepts = _accepts(
    visitor.maritalStatus,
    candidate.acceptedMarital,
  );
  if (visitorAccepts && candidateAccepts) return 20;
  if (visitorAccepts || candidateAccepts) return 10;
  return 0;
}

bool _accepts(String? status, List<String> accepted) {
  if (status == null || status.isEmpty) return false;
  return accepted.contains(status);
}
