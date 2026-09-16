import 'package:agapeo/core/config/app_environment.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/presentation/age_gate/age_gate_page.dart';
import 'package:agapeo/features/auth/presentation/session_stub/session_stub_page.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
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
    required FakeAgeGateStore ageGate,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          ageGateStoreProvider.overrideWithValue(ageGate),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const SplashPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'does not throw without auth override when Supabase env is empty',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ageGateStoreProvider.overrideWithValue(FakeAgeGateStore()),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const SplashPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AgeGatePage), findsOneWidget);
    },
  );

  testWidgets('routes to age gate when no session and gate not accepted', (
    tester,
  ) async {
    await pumpSplash(
      tester,
      auth: FakeAuthRepository(),
      ageGate: FakeAgeGateStore(),
    );

    expect(find.byType(AgeGatePage), findsOneWidget);
  });

  testWidgets('routes to welcome when no session and gate accepted', (
    tester,
  ) async {
    await pumpSplash(
      tester,
      auth: FakeAuthRepository(),
      ageGate: FakeAgeGateStore(accepted: true),
    );

    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets('routes to session stub when session exists', (tester) async {
    await pumpSplash(
      tester,
      auth: FakeAuthRepository(
        currentSession: const AuthSession(id: '1', email: 'a@b.co'),
      ),
      ageGate: FakeAgeGateStore(),
    );

    expect(find.byType(SessionStubPage), findsOneWidget);
    expect(find.textContaining('a@b.co'), findsOneWidget);
  });
}
