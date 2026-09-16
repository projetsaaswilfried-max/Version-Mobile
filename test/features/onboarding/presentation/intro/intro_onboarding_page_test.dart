import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
import 'package:agapeo/features/onboarding/di/onboarding_providers.dart';
import 'package:agapeo/features/onboarding/presentation/intro/intro_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  Future<void> pumpIntro(WidgetTester tester, FakeIntroStore intro) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [introStoreProvider.overrideWithValue(intro)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const IntroOnboardingPage(),
        ),
      ),
    );
  }

  testWidgets('shows first slide title and Passer', (tester) async {
    final intro = FakeIntroStore();
    await pumpIntro(tester, intro);

    expect(find.text('Rencontres sincères'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('Passer marks intro seen and opens Welcome', (tester) async {
    final intro = FakeIntroStore();
    await pumpIntro(tester, intro);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(await intro.isSeen(), isTrue);
    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets('Suivant then Continuer opens Welcome', (tester) async {
    final intro = FakeIntroStore();
    await pumpIntro(tester, intro);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('La foi au centre'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Prêt à commencer'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(await intro.isSeen(), isTrue);
    expect(find.byType(WelcomePage), findsOneWidget);
  });
}
