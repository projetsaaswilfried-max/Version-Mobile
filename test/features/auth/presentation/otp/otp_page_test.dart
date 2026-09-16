import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/presentation/otp/otp_page.dart';
import 'package:agapeo/features/auth/presentation/verify_email/verify_email_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

void main() {
  testWidgets('shows 6-digit prompt, email, resend and no password', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OtpPage(email: 'a@b.co', password: 'Secret12'),
        ),
      ),
    );

    expect(find.text('Saisis le code à 6 chiffres'), findsOneWidget);
    expect(find.text('a@b.co'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
    expect(find.text('Renvoyer le code'), findsOneWidget);
    expect(find.text("Tu n'as pas reçu de code ?"), findsOneWidget);
    expect(find.byType(Pinput), findsOneWidget);
    expect(find.text('Secret12'), findsNothing);
    expect(find.text('Google'), findsNothing);
  });

  testWidgets('help CTA opens verify email without showing password', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OtpPage(email: 'a@b.co', password: 'Secret12'),
        ),
      ),
    );

    await tester.ensureVisible(find.text("Tu n'as pas reçu de code ?"));
    await tester.tap(find.text("Tu n'as pas reçu de code ?"));
    // pumpAndSettle would time out on Pinput's blinking cursor animation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(VerifyEmailPage), findsOneWidget);
    expect(find.text('a@b.co'), findsWidgets);
    expect(find.text('Secret12'), findsNothing);
  });
}
