import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/account_person.dart';
import 'package:agapeo/features/profile/presentation/interested/interested_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/profile_account_test_fakes.dart';

void main() {
  testWidgets('hides identities when not premium', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(
              interested: const InterestedPeople(
                count: 2,
                revealIdentities: false,
                people: [
                  AccountPerson(
                    id: '3',
                    displayName: 'No***',
                    identityRevealed: false,
                  ),
                ],
              ),
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const InterestedPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('2 personnes s\'intéressent à toi'), findsOneWidget);
    expect(find.text('Voir les identités avec Premium'), findsOneWidget);
  });
}
