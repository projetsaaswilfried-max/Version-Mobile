import '../entities/member_gate_snapshot.dart';
import '../entities/post_login_destination.dart';

class ResolvePostLoginRoute {
  const ResolvePostLoginRoute();

  /// Un abonnement `EXPIRED` ne bloque pas l'app entière - seuls Découvrir,
  /// Messages et Support sont verrouillés (leurs propres gates), exactement
  /// comme le PRD §3 le décrit. Un `EXPIRED` route donc comme un `FREE`.
  PostLoginDestination call(MemberGateSnapshot snapshot) {
    if (snapshot.isSuspended) return PostLoginDestination.suspended;
    if (!snapshot.onboardingCompleted) {
      return PostLoginDestination.onboarding;
    }
    return PostLoginDestination.home;
  }
}
