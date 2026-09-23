import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/domain/entities/auth_session.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/presentation/my_profile/my_profile_page.dart';
import 'package:agapeo/features/profile/presentation/security/photos_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';
import '../../../../helpers/profile_test_fakes.dart';

_overrides(FakeMyProfileRepository repo) {
  return [
    myProfileRepositoryProvider.overrideWithValue(repo),
    profileFieldsRepositoryProvider.overrideWithValue(
      FakeProfileFieldsRepository(result: Ok(fakeProfileFieldsSnapshot())),
    ),
    authRepositoryProvider.overrideWithValue(
      FakeAuthRepository(
        currentSession: const AuthSession(id: '1', email: 'lea@agapeo.love'),
      ),
    ),
  ];
}

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    FakeMyProfileRepository? repo,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          repo ?? FakeMyProfileRepository(fetchResult: Ok(fakeMyProfile())),
        ),
        child: MaterialApp(theme: AppTheme.light, home: const MyProfilePage()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows identity fields and save', (tester) async {
    await pumpPage(tester);

    expect(find.text('Enregistrer'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Ajouter ta photo de profil'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('Genre'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Genre'), findsOneWidget);
    expect(find.text('Non modifiables après validation'), findsOneWidget);
    expect(find.text('Femme'), findsOneWidget);
    expect(find.text('04/03/1992'), findsOneWidget);
    expect(find.text('France'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Prénom'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Prénom'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nom'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Nom'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ville'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Ville'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Profession'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Profession'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bio'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Bio'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('5/600'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('5/600'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Prêt à déménager'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Prêt à déménager'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Confession chrétienne'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Confession chrétienne'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Situation matrimoniale'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Situation matrimoniale'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pourquoi cherches-tu le mariage ?'),
      80,
      scrollable: scrollable,
    );
    expect(find.text('Pourquoi cherches-tu le mariage ?'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Ma Foi'),
      80,
      scrollable: scrollable,
    );
    expect(find.textContaining('Ma Foi'), findsOneWidget);
  });

  testWidgets('hides add photo when verified', (tester) async {
    await pumpPage(
      tester,
      repo: FakeMyProfileRepository(
        fetchResult: Ok(fakeMyProfile(isVerified: true)),
      ),
    );

    expect(find.bySemanticsLabel('Ajouter une photo'), findsNothing);
  });

  testWidgets('verified: "Gérer mes photos" opens PhotosManagementPage', (
    tester,
  ) async {
    await pumpPage(
      tester,
      repo: FakeMyProfileRepository(
        fetchResult: Ok(fakeMyProfile(isVerified: true)),
      ),
    );

    expect(find.text('Gérer mes photos'), findsOneWidget);
    await tester.tap(find.text('Gérer mes photos'));
    await tester.pumpAndSettle();

    expect(find.byType(PhotosManagementPage), findsOneWidget);
  });

  testWidgets('save pops after success', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          FakeMyProfileRepository(fetchResult: Ok(fakeMyProfile())),
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyProfilePage(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.byType(MyProfilePage), findsNothing);
    expect(find.text('Profil enregistré.'), findsOneWidget);
  });
}
