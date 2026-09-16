import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/presentation/age_gate/age_gate_page.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  Future<void> pumpAgeGate(WidgetTester tester, FakeAgeGateStore store) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ageGateStoreProvider.overrideWithValue(store)],
        child: MaterialApp(theme: AppTheme.light, home: const AgeGatePage()),
      ),
    );
  }

  testWidgets('accept persists and navigates to welcome', (tester) async {
    final store = FakeAgeGateStore();
    await pumpAgeGate(tester, store);

    await tester.tap(find.text("J'ai 18 ans ou plus"));
    await tester.pumpAndSettle();

    expect(await store.isAccepted(), isTrue);
    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets('refuse shows error and does not navigate', (tester) async {
    final store = FakeAgeGateStore();
    await pumpAgeGate(tester, store);

    await tester.tap(find.text("Je n'ai pas 18 ans"));
    await tester.pump();

    expect(find.byType(AgeGatePage), findsOneWidget);
    expect(find.byType(WelcomePage), findsNothing);
    expect(await store.isAccepted(), isFalse);
    expect(
      find.text('Agapéo est réservé aux personnes de 18 ans et plus.'),
      findsOneWidget,
    );
  });
}
