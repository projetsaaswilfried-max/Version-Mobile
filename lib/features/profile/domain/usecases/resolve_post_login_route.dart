import '../../../../core/config/debug_flags.dart';
import '../entities/member_gate_snapshot.dart';
import '../entities/post_login_destination.dart';
import '../entities/subscription_status.dart';

class ResolvePostLoginRoute {
  const ResolvePostLoginRoute();

  PostLoginDestination call(MemberGateSnapshot snapshot) {
    if (snapshot.isSuspended) return PostLoginDestination.suspended;
    if (!kBypassPremiumGatesForTesting &&
        snapshot.subscriptionStatus == SubscriptionStatus.expired) {
      return PostLoginDestination.expired;
    }
    if (!snapshot.onboardingCompleted) {
      return PostLoginDestination.onboarding;
    }
    return PostLoginDestination.home;
  }
}
