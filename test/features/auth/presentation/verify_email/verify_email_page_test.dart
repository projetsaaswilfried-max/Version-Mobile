import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/presentation/verify_email/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows email, confirm and resend without password', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const VerifyEmailPage(email: 'a@b.co', password: 'Secret12'),
        ),
      ),
    );

    expect(find.text('Vérifie tes mails'), findsWidgets);
    expect(find.text('a@b.co'), findsOneWidget);
    expect(find.text("J'ai confirmé"), findsOneWidget);
    expect(find.text('Renvoyer'), findsOneWidget);
    expect(find.text('Secret12'), findsNothing);
    expect(find.text('Google'), findsNothing);
  });
}
