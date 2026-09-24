import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/presentation/security/account_security_page.dart';
import 'package:agapeo/features/profile/presentation/security/add_profile_photo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/profile_account_test_fakes.dart';
import '../../../../helpers/profile_test_fakes.dart';

void main() {
  testWidgets('security hub lists actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(),
          ),
          myProfileRepositoryProvider.overrideWithValue(
            FakeMyProfileRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AccountSecurityPage(),
        ),
      ),
    );

    expect(find.text('Vérification'), findsOneWidget);
    expect(find.text('Changer l\'email'), findsOneWidget);
    expect(find.text('Changer le mot de passe'), findsOneWidget);
    expect(find.text('Export des données'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Mentions légales'), findsOneWidget);
    expect(
      find.text('Mon Plan'),
      findsNothing,
      reason: 'déplacé dans le menu Profil, sous Plus d\'infos',
    );
    expect(find.text('Comptes bloqués'), findsOneWidget);
    expect(find.text('Supprimer mon compte'), findsOneWidget);

    await tester.tap(find.text('Vérification'));
    await tester.pumpAndSettle();
    expect(find.byType(AddProfilePhotoPage), findsOneWidget);
  });
}
