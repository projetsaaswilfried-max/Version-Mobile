import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/presentation/otp/otp_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinput/pinput.dart';

void main() {
  testWidgets('shows 6-digit prompt, email and resend', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OtpPage(email: 'a@b.co'),
        ),
      ),
    );

    expect(find.text('Saisis le code à 6 chiffres'), findsOneWidget);
    expect(find.text('a@b.co'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
    expect(find.text('Renvoyer le code'), findsOneWidget);
    expect(find.byType(Pinput), findsOneWidget);
    expect(find.text('Google'), findsNothing);
  });
}
