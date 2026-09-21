class CandidateEligibility {
  const CandidateEligibility({
    required this.id,
    required this.gender,
    required this.isStaff,
    required this.isVerified,
    required this.isMatched,
    required this.isComplete,
  });

  final String id;
  final String? gender;
  final bool isStaff;
  final bool isVerified;
  final bool isMatched;
  final bool isComplete;
}

/// Hypothèse de travail D01 (docs/decisions.md Q1, encore EN ATTENTE) :
/// la liste suit PRD §7. §3 et §6 restent contradictoires ; ne pas traiter
/// cette interprétation comme tranchée.
bool isDiscoverEligible({
  required String visitorGender,
  required CandidateEligibility candidate,
}) {
  if (candidate.isStaff) return false;
  if (!candidate.isVerified) return false;
  if (candidate.isMatched) return false;
  if (!candidate.isComplete) return false;
  return _isOppositeGender(visitorGender, candidate.gender);
}

bool _isOppositeGender(String visitorGender, String? candidateGender) {
  if (candidateGender == null) return false;
  if (visitorGender == 'MALE') return candidateGender == 'FEMALE';
  if (visitorGender == 'FEMALE') return candidateGender == 'MALE';
  return false;
}
