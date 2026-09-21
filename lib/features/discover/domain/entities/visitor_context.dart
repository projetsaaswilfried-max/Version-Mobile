import '../../../profile/domain/entities/subscription_status.dart';
import '../scoring/compatibility_traits.dart';

class VisitorContext {
  const VisitorContext({
    required this.id,
    required this.gender,
    required this.isVerified,
    required this.subscriptionStatus,
    required this.traits,
    this.isStaff = false,
  });

  final String id;
  final String? gender;
  final bool isVerified;
  final String subscriptionStatus;
  final CompatibilityTraits traits;
  final bool isStaff;

  SubscriptionStatus get subscription =>
      parseSubscriptionStatus(subscriptionStatus);

  bool get isPremiumActive => subscription == SubscriptionStatus.active;
  bool get isExpired => subscription == SubscriptionStatus.expired;
}

/// Traits utiles au score §7 encore vides (bannière D04).
bool hasIncompleteCompatibilityTraits(CompatibilityTraits traits) {
  return traits.confession == null ||
      traits.spiritualEngagement == null ||
      traits.values.isEmpty ||
      traits.hobbies.isEmpty;
}
