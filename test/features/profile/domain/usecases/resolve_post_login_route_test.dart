import 'package:agapeo/features/profile/domain/entities/member_gate_snapshot.dart';
import 'package:agapeo/features/profile/domain/entities/post_login_destination.dart';
import 'package:agapeo/features/profile/domain/entities/subscription_status.dart';
import 'package:agapeo/features/profile/domain/usecases/resolve_post_login_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolve = ResolvePostLoginRoute();

  test('suspended wins over incomplete onboarding', () {
    final dest = resolve(
      const MemberGateSnapshot(
        isSuspended: true,
        subscriptionStatus: SubscriptionStatus.expired,
        onboardingCompleted: false,
      ),
    );
    expect(dest, PostLoginDestination.suspended);
  });

  test(
    'EXPIRED does not lock the whole app (PRD §3: only Découvrir/'
    'Messages/Support, gated individually) - routes like FREE',
    () {
      expect(
        resolve(
          const MemberGateSnapshot(
            isSuspended: false,
            subscriptionStatus: SubscriptionStatus.expired,
            onboardingCompleted: true,
          ),
        ),
        PostLoginDestination.home,
      );
    },
  );

  test('onboarding when not suspended and incomplete', () {
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

  test('CANCELED also routes home', () {
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
