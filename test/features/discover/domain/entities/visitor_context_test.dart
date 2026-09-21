import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium ACTIVE is not expired', () {
    const visitor = VisitorContext(
      id: 'v1',
      gender: 'MALE',
      isVerified: false,
      subscriptionStatus: 'ACTIVE',
      traits: CompatibilityTraits(),
    );
    expect(visitor.isPremiumActive, isTrue);
    expect(visitor.isExpired, isFalse);
    expect(visitor.subscription.name, 'active');
  });

  test('incomplete when faith values or hobbies missing', () {
    expect(
      hasIncompleteCompatibilityTraits(const CompatibilityTraits()),
      isTrue,
    );
    expect(
      hasIncompleteCompatibilityTraits(
        const CompatibilityTraits(
          confession: 'c',
          spiritualEngagement: 'e',
          values: ['v'],
          hobbies: ['h'],
        ),
      ),
      isFalse,
    );
  });
}
