import 'package:agapeo/core/config/app_environment.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/presentation/age_gate/age_gate_page.dart';
import 'package:agapeo/features/auth/presentation/session_stub/session_stub_page.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
import 'package:agapeo/features/onboarding/di/onboarding_providers.dart';
import 'package:agapeo/features/onboarding/presentation/intro/intro_onboarding_page.dart';
import 'package:agapeo/features/onboarding/presentation/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  setUpAll(() {
    try {
      AppEnvironment.init();
    } catch (_) {
      // Already initialized by another test in this VM.
    }
  });

  Future<void> pumpSplash(
    WidgetTester tester, {
    required FakeAuthRepository auth,
    required FakeIntroStore intro,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          introStoreProvider.overrideWithValue(intro),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const SplashPage()),
      ),
    );
    await tester.pump();
    await tester.pump(SplashPage.minDisplayDuration);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'does not throw without auth override when Supabase env is empty',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            introStoreProvider.overrideWithValue(FakeIntroStore()),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const SplashPage()),
        ),
      );
      await tester.pump();
      await tester.pump(SplashPage.minDisplayDuration);
      await tester.pumpAndSettle();

      expect(find.byType(IntroOnboardingPage), findsOneWidget);
      expect(find.byType(AgeGatePage), findsNothing);
    },
  );

  testWidgets('keeps splash visible until min display duration', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          introStoreProvider.overrideWithValue(FakeIntroStore()),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const SplashPage()),
      ),
    );
    await tester.pump();
    expect(find.byType(SplashPage), findsOneWidget);
    expect(find.byType(IntroOnboardingPage), findsNothing);

    await tester.pump(
      SplashPage.minDisplayDuration - const Duration(milliseconds: 1),
    );
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(IntroOnboardingPage), findsOneWidget);
  });

  testWidgets('routes to intro when no session and intro not seen', (
    tester,
  ) async {
    await pumpSplash(
      tester,
      auth: FakeAuthRepository(),
      intro: FakeIntroStore(),
    );

    expect(find.byType(IntroOnboardingPage), findsOneWidget);
    expect(find.byType(AgeGatePage), findsNothing);
  });

  testWidgets('routes to welcome when no session and intro seen', (
    tester,
  ) async {
    await pumpSplash(
      tester,
      auth: FakeAuthRepository(),
      intro: FakeIntroStore(seen: true),
    );

    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets('routes to session stub when session exists', (tester) async {
    await pumpSplash(
      tester,
      auth: FakeAuthRepository(
        currentSession: const AuthSession(id: '1', email: 'a@b.co'),
      ),
      intro: FakeIntroStore(),
    );

    expect(find.byType(SessionStubPage), findsOneWidget);
    expect(find.textContaining('a@b.co'), findsOneWidget);
  });
}
