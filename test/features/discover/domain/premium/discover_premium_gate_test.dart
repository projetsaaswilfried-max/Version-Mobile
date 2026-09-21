import 'package:agapeo/features/discover/domain/premium/discover_premium_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FREE and CANCELED show the sheet', () {
    expect(
      shouldShowDiscoverPremiumSheet(subscriptionStatus: 'FREE'),
      isTrue,
    );
    expect(
      shouldShowDiscoverPremiumSheet(subscriptionStatus: 'CANCELED'),
      isTrue,
    );
  });

  test('ACTIVE and EXPIRED do not show the sheet', () {
    expect(
      shouldShowDiscoverPremiumSheet(subscriptionStatus: 'ACTIVE'),
      isFalse,
    );
    expect(
      shouldShowDiscoverPremiumSheet(subscriptionStatus: 'EXPIRED'),
      isFalse,
    );
  });

  test('staff never sees the sheet', () {
    expect(
      shouldShowDiscoverPremiumSheet(
        subscriptionStatus: 'FREE',
        isStaff: true,
      ),
      isFalse,
    );
  });

  test('ACTIVE and staff can use search filters', () {
    expect(canUseDiscoverSearchFilters(subscriptionStatus: 'ACTIVE'), isTrue);
    expect(
      canUseDiscoverSearchFilters(subscriptionStatus: 'FREE', isStaff: true),
      isTrue,
    );
  });

  test('FREE CANCELED EXPIRED cannot use search filters', () {
    expect(canUseDiscoverSearchFilters(subscriptionStatus: 'FREE'), isFalse);
    expect(canUseDiscoverSearchFilters(subscriptionStatus: 'CANCELED'), isFalse);
    expect(canUseDiscoverSearchFilters(subscriptionStatus: 'EXPIRED'), isFalse);
  });

  test('canOpenDiscoverProfile requires verified or staff', () {
    expect(canOpenDiscoverProfile(visitorVerified: true), isTrue);
    expect(
      canOpenDiscoverProfile(visitorVerified: false, isStaff: true),
      isTrue,
    );
    expect(canOpenDiscoverProfile(visitorVerified: false), isFalse);
  });

  test('canLikeDiscoverProfile requires verified or staff', () {
    expect(canLikeDiscoverProfile(visitorVerified: true), isTrue);
    expect(canLikeDiscoverProfile(visitorVerified: false), isFalse);
    expect(
      canLikeDiscoverProfile(visitorVerified: false, isStaff: true),
      isTrue,
    );
  });

  test('canFavoriteDiscoverProfile requires verified or staff', () {
    expect(canFavoriteDiscoverProfile(visitorVerified: true), isTrue);
    expect(canFavoriteDiscoverProfile(visitorVerified: false), isFalse);
    expect(
      canFavoriteDiscoverProfile(visitorVerified: false, isStaff: true),
      isTrue,
    );
  });

  test('canInviteDiscoverProfile requires verified or staff', () {
    expect(canInviteDiscoverProfile(visitorVerified: true), isTrue);
    expect(canInviteDiscoverProfile(visitorVerified: false), isFalse);
    expect(
      canInviteDiscoverProfile(visitorVerified: false, isStaff: true),
      isTrue,
    );
  });

  test('canSendFreeInvitation staff and ACTIVE are unlimited', () {
    expect(
      canSendFreeInvitation(
        subscriptionStatus: 'FREE',
        monthlyCount: 99,
        isStaff: true,
      ),
      isTrue,
    );
    expect(
      canSendFreeInvitation(
        subscriptionStatus: 'ACTIVE',
        monthlyCount: 99,
      ),
      isTrue,
    );
  });

  test('canSendFreeInvitation FREE and CANCELED allow under 3 per month', () {
    for (final status in ['FREE', 'CANCELED']) {
      expect(
        canSendFreeInvitation(subscriptionStatus: status, monthlyCount: 0),
        isTrue,
      );
      expect(
        canSendFreeInvitation(subscriptionStatus: status, monthlyCount: 2),
        isTrue,
      );
      expect(
        canSendFreeInvitation(subscriptionStatus: status, monthlyCount: 3),
        isFalse,
      );
    }
  });

  test('canSendFreeInvitation EXPIRED denies send', () {
    expect(
      canSendFreeInvitation(subscriptionStatus: 'EXPIRED', monthlyCount: 0),
      isFalse,
    );
  });
}
