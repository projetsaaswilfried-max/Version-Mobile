import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_text_field.dart';
import 'package:agapeo/features/auth/presentation/forgot_password/forgot_password_page.dart';
import 'package:agapeo/features/auth/presentation/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows email, password, CTA and no Google', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
      ),
    );

    expect(find.byType(AppTextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Mot de passe oublié'), findsOneWidget);
    expect(find.text('CGU'), findsOneWidget);
    expect(find.text('Confidentialité'), findsOneWidget);
    expect(find.text('Google'), findsNothing);
  });

  testWidgets('Mot de passe oublié opens forgot password', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const LoginPage()),
      ),
    );

    await tester.tap(find.text('Mot de passe oublié'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
  });
}
