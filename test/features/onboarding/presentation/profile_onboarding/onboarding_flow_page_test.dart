import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/home/presentation/home_shell_page.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_controller.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  testWidgets('shell profile opens onboarding flow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HomeShellPage(),
        ),
      ),
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuer l\'onboarding'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlowPage), findsOneWidget);
    expect(find.text('Informations essentielles'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('next shows validation when essentials empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    await tester.tap(find.text('Suivant'));
    await tester.pump();

    expect(find.text('Choisis ton genre.'), findsOneWidget);
    expect(find.text('Tes photos'), findsNothing);
  });

  testWidgets(
    'shows Revenir plus tard and opens HomeShell without completing',
    (tester) async {
      final repo = FakeAuthRepository(
        currentSession: const AuthSession(id: '1', email: 'user@test.co'),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OnboardingFlowPage(),
          ),
        ),
      );

      expect(find.text('Revenir plus tard'), findsOneWidget);

      await tester.tap(find.text('Revenir plus tard'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeShellPage), findsOneWidget);
      expect(
        container.read(onboardingFlowProvider).completedLocally,
        isFalse,
      );
    },
  );
}
