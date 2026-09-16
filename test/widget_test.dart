import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/onboarding/di/onboarding_providers.dart';
import 'package:agapeo/features/onboarding/presentation/intro/intro_onboarding_page.dart';
import 'package:agapeo/features/onboarding/presentation/splash/splash_page.dart';
import 'package:agapeo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/auth_test_fakes.dart';

void main() {
  testWidgets('AgapeoApp shows the splash page', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ageGateStoreProvider.overrideWithValue(FakeAgeGateStore()),
          introStoreProvider.overrideWithValue(FakeIntroStore()),
        ],
        child: const AgapeoApp(),
      ),
    );

    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump();
    await tester.pump(SplashPage.minDisplayDuration);
    await tester.pumpAndSettle();
  });

  testWidgets('AgapeoApp routes from splash to intro', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ageGateStoreProvider.overrideWithValue(FakeAgeGateStore()),
          introStoreProvider.overrideWithValue(FakeIntroStore()),
        ],
        child: const AgapeoApp(),
      ),
    );
    await tester.pump();
    await tester.pump(SplashPage.minDisplayDuration);
    await tester.pumpAndSettle();

    expect(find.byType(IntroOnboardingPage), findsOneWidget);
  });
}
