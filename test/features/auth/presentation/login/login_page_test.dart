import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_text_field.dart';
import 'package:agapeo/features/auth/presentation/forgot_password/forgot_password_page.dart';
import 'package:agapeo/features/auth/presentation/login/login_page.dart';
import 'package:agapeo/features/auth/presentation/registration/registration_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
      ),
    );
  }

  testWidgets('shows Datify-style login fields, CTA and Google', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Heureux de te revoir sur Agapeo.'), findsOneWidget);
    expect(find.byType(AppTextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.bySemanticsLabel('Continuer avec Google'), findsOneWidget);
    expect(find.text('CGU'), findsOneWidget);
    expect(find.text('Confidentialité'), findsOneWidget);
  });

  testWidgets('Mot de passe oublié opens forgot password', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });

  testWidgets('Créer un compte opens registration', (tester) async {
    await pumpLogin(tester);

    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationPage), findsOneWidget);
  });
}
