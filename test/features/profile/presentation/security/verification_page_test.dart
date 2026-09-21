import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/verification_info.dart';
import 'package:agapeo/features/profile/presentation/security/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/profile_account_test_fakes.dart';

Future<void> pumpVerification(
  WidgetTester tester, {
  required VerificationInfo verification,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileAccountRepositoryProvider.overrideWithValue(
          FakeProfileAccountRepository(verification: verification),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const VerificationPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('VERIFIED shows the success hero and no submit button', (
    tester,
  ) async {
    await pumpVerification(
      tester,
      verification: const VerificationInfo(status: 'VERIFIED', isComplete: true),
    );

    expect(find.text('Profil vérifié'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(find.text('Soumettre un selfie'), findsNothing);
  });

  testWidgets('PENDING shows the SLA info card', (tester) async {
    await pumpVerification(
      tester,
      verification: const VerificationInfo(status: 'PENDING', isComplete: true),
    );

    expect(find.text('Vérification en cours'), findsOneWidget);
    expect(find.text('Délai d\'examen'), findsOneWidget);
    expect(find.text('Soumettre un selfie'), findsNothing);
  });

  testWidgets('REJECTED shows the rejection reason', (tester) async {
    await pumpVerification(
      tester,
      verification: const VerificationInfo(
        status: 'REJECTED',
        isComplete: true,
        rejectionReason: 'Le selfie ne correspond pas à tes photos.',
      ),
    );

    expect(find.text('Vérification refusée'), findsOneWidget);
    expect(find.text('Motif du refus'), findsOneWidget);
    expect(
      find.text('Le selfie ne correspond pas à tes photos.'),
      findsOneWidget,
    );
    expect(find.text('Soumettre un selfie'), findsOneWidget);
  });

  testWidgets('incomplete profile shows the requirements checklist', (
    tester,
  ) async {
    await pumpVerification(
      tester,
      verification: const VerificationInfo(
        status: 'UNVERIFIED',
        isComplete: false,
      ),
    );

    expect(find.text('Non vérifié'), findsOneWidget);
    expect(find.text('Complète ton profil pour soumettre'), findsOneWidget);
    expect(find.text('Une photo de profil principale'), findsOneWidget);
    expect(find.text('Soumettre un selfie'), findsNothing);
  });

  testWidgets('complete profile shows the submit button and camera note', (
    tester,
  ) async {
    await pumpVerification(
      tester,
      verification: const VerificationInfo(
        status: 'UNVERIFIED',
        isComplete: true,
      ),
    );

    expect(find.text('Soumettre un selfie'), findsOneWidget);
    expect(find.text('Selfie en direct'), findsOneWidget);
  });
}
