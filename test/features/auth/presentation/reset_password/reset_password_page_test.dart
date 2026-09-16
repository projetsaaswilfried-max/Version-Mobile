import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/presentation/reset_password/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows password fields and save CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ResetPasswordPage(),
        ),
      ),
    );

    expect(find.text('Nouveau mot de passe'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Confirmer le mot de passe'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
    expect(find.text('Retour à la connexion'), findsOneWidget);
  });
}
