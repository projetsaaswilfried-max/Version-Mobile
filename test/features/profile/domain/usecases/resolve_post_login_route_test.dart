import 'package:agapeo/features/profile/domain/entities/member_gate_snapshot.dart';
import 'package:agapeo/features/profile/domain/entities/post_login_destination.dart';
import 'package:agapeo/features/profile/domain/entities/subscription_status.dart';
import 'package:agapeo/features/profile/domain/usecases/resolve_post_login_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolve = ResolvePostLoginRoute();

  test('suspended wins over expired and incomplete onboarding', () {
    final dest = resolve(
      const MemberGateSnapshot(
        isSuspended: true,
        subscriptionStatus: SubscriptionStatus.expired,
        onboardingCompleted: false,
      ),
    );
    expect(dest, PostLoginDestination.suspended);
  });

  test('expired when not suspended', () {
    expect(
      resolve(
        const MemberGateSnapshot(
          isSuspended: false,
          subscriptionStatus: SubscriptionStatus.expired,
          onboardingCompleted: true,
        ),
      ),
      PostLoginDestination.expired,
    );
  });

  test('onboarding when not suspended and not expired', () {
    expect(
      resolve(
        const MemberGateSnapshot(
          isSuspended: false,
          subscriptionStatus: SubscriptionStatus.free,
          onboardingCompleted: false,
        ),
      ),
      PostLoginDestination.onboarding,
    );
  });

  test('home otherwise', () {
    expect(
      resolve(
        const MemberGateSnapshot(
          isSuspended: false,
          subscriptionStatus: SubscriptionStatus.active,
          onboardingCompleted: true,
        ),
      ),
      PostLoginDestination.home,
    );
  });

  test('CANCELED is not EXPIRED wall', () {
    expect(
      resolve(
        const MemberGateSnapshot(
          isSuspended: false,
          subscriptionStatus: SubscriptionStatus.canceled,
          onboardingCompleted: true,
        ),
      ),
      PostLoginDestination.home,
    );
  });
}
