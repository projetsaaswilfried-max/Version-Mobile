/// `verification_requests` (dernière ligne) fait foi pour PENDING/REJECTED
/// - `profiles.photo_verification_status` ne se synchronise pas de façon
/// fiable sur ces transitions (confirmé par SQL direct). Mais pour VERIFIED,
/// l'inverse est vrai : supprimer la photo principale remet
/// `photo_verification_status` à UNVERIFIED côté serveur sans jamais créer
/// de nouvelle ligne `verification_requests` - la dernière requête reste
/// VERIFIED indéfiniment. Ne faire confiance à un VERIFIED de
/// `verification_requests` que si `profiles` est d'accord ; sinon `profiles`
/// a la priorité (signal plus frais pour cette transition).
String? resolveVerificationStatus({
  required String? requestStatus,
  required String? profileStatus,
}) {
  if (requestStatus == null) return profileStatus;
  if (requestStatus.toUpperCase() != 'VERIFIED') return requestStatus;
  return profileStatus?.toUpperCase() == 'VERIFIED'
      ? requestStatus
      : profileStatus;
}
