import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/premium/presentation/premium_plan_page.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/member_gate_snapshot.dart';
import 'package:agapeo/features/profile/domain/entities/subscription_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpPlan(
  WidgetTester tester, {
  required SubscriptionStatus status,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memberGateProvider.overrideWith(
          (ref) async => Ok(
            MemberGateSnapshot(
              isSuspended: false,
              subscriptionStatus: status,
              onboardingCompleted: true,
            ),
          ),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light, home: const PremiumPlanPage()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('ACTIVE shows the Premium actif status pill', (tester) async {
    await pumpPlan(tester, status: SubscriptionStatus.active);

    expect(find.text('Premium actif'), findsOneWidget);
  });

  testWidgets('FREE shows Gratuit and lists every plan with one recommended', (
    tester,
  ) async {
    await pumpPlan(tester, status: SubscriptionStatus.free);

    expect(find.text('Gratuit'), findsOneWidget);
    expect(find.text('1 semaine'), findsOneWidget);
    expect(find.text('Trimestriel'), findsOneWidget);
    expect(find.text('Recommandé'), findsOneWidget);
  });

  testWidgets('shows the benefits list and the agapeo.love link', (
    tester,
  ) async {
    await pumpPlan(tester, status: SubscriptionStatus.free);

    expect(find.text('Avantages Premium'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('agapeo.love'),
      find.byType(Scrollable),
      const Offset(0, -300),
    );
    expect(find.text('agapeo.love'), findsOneWidget);
  });
}
