import 'package:equatable/equatable.dart';

import 'subscription_status.dart';

class MemberGateSnapshot extends Equatable {
  const MemberGateSnapshot({
    required this.isSuspended,
    required this.subscriptionStatus,
    required this.onboardingCompleted,
  });

  final bool isSuspended;
  final SubscriptionStatus subscriptionStatus;
  final bool onboardingCompleted;

  @override
  List<Object?> get props =>
      [isSuspended, subscriptionStatus, onboardingCompleted];
}
