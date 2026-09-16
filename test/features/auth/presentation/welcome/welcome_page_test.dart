import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/presentation/login/login_page.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_page.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpWelcome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const WelcomePage()),
      ),
    );
  }

  testWidgets('shows connect CTA and tagline', (tester) async {
    await pumpWelcome(tester);

    expect(find.text('Bienvenue'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(
      find.text('Des rencontres sincères pour bâtir un foyer chrétien.'),
      findsOneWidget,
    );
  });

  testWidgets('Se connecter opens login', (tester) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('Créer un compte opens registration', (tester) async {
    await pumpWelcome(tester);

    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationPage), findsOneWidget);
  });
}
