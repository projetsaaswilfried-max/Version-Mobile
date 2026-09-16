import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/presentation/login/login_page.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_page.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  Future<void> pumpWelcome(
    WidgetTester tester, {
    FakeAuthRepository? auth,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            auth ?? FakeAuthRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const WelcomePage()),
      ),
    );
  }

  testWidgets('shows Nestle-style CTAs, Google and tagline', (tester) async {
    await pumpWelcome(tester);

    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('ou continuer avec'), findsOneWidget);
    expect(find.text('Continuer avec Google'), findsOneWidget);
    expect(
      find.text('Des rencontres sincères pour bâtir un foyer chrétien.'),
      findsOneWidget,
    );
  });

  testWidgets('Se connecter opens login', (tester) async {
    await pumpWelcome(tester);

    await tester.ensureVisible(find.text('Se connecter'));
    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('Créer un compte opens registration', (tester) async {
    await pumpWelcome(tester);

    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationPage), findsOneWidget);
  });

  testWidgets('Google triggers OAuth launch without coming-soon snackbar', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await pumpWelcome(tester, auth: auth);

    await tester.ensureVisible(find.text('Continuer avec Google'));
    await tester.tap(find.text('Continuer avec Google'));
    await tester.pump();

    expect(auth.signInWithGoogleCalled, isTrue);
    expect(find.text('Connexion Google bientôt disponible.'), findsNothing);
  });
}
