import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
import 'package:agapeo/features/home/presentation/home_shell_controller.dart';
import 'package:agapeo/features/home/presentation/home_shell_page.dart';
import 'package:agapeo/features/home/presentation/notifications/notifications_stub_page.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/auth_test_fakes.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    FakeAuthRepository? auth,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            auth ??
                FakeAuthRepository(
                  currentSession: const AuthSession(
                    id: '1',
                    email: 'user@test.co',
                  ),
                ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const HomeShellPage(),
        ),
      ),
    );
  }

  testWidgets('shows four nav destinations and no fifth', (tester) async {
    await pumpShell(tester);

    expect(find.text('Fil'), findsWidgets);
    expect(find.text('Découvrir'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });

  testWidgets('selecting Découvrir shows discover placeholder', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('Découvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Découvrir'), findsWidgets);
    expect(find.text('Bientôt'), findsOneWidget);
  });

  testWidgets('bell opens notifications stub without badge at zero', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byType(Badge), findsNothing);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsStubPage), findsOneWidget);
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('profile Continuer l\'onboarding opens OnboardingFlowPage', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continuer l\'onboarding'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlowPage), findsOneWidget);
  });

  testWidgets('profile Déconnexion opens WelcomePage', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('user@test.co'), findsOneWidget);

    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);
  });

  test('homeShellIndexProvider est autoDispose', () {
    expect(homeShellIndexProvider.isAutoDispose, isTrue);
  });

  test(
    'l\'index sélectionné revient à Fil (0) après démontage du shell',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(homeShellIndexProvider, (_, _) {});
      container.read(homeShellIndexProvider.notifier).select(2);
      expect(container.read(homeShellIndexProvider), 2);

      subscription.close();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(homeShellIndexProvider), 0);
    },
  );
}
