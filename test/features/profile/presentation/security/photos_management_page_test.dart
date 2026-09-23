import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/my_profile_photo.dart';
import 'package:agapeo/features/profile/presentation/security/photos_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/profile_account_test_fakes.dart';
import '../../../../helpers/profile_test_fakes.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required FakeMyProfileRepository myProfile,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myProfileRepositoryProvider.overrideWithValue(myProfile),
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PhotosManagementPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  const kPhotos = [
    MyProfilePhoto(id: 'p1', publicUrl: 'https://cdn/a.jpg'),
    MyProfilePhoto(id: 'p2', publicUrl: 'https://cdn/b.jpg'),
  ];

  testWidgets(
    'supprimer la photo principale avertit même s\'il en reste d\'autres',
    (tester) async {
      final myProfile = FakeMyProfileRepository(
        fetchResult: Ok(
          fakeMyProfile(isVerified: true, photos: kPhotos),
        ),
      );
      await pumpPage(tester, myProfile: myProfile);

      final removeButtons = find.byTooltip('Retirer la photo');
      expect(removeButtons, findsNWidgets(2));

      await tester.tap(removeButtons.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('Tu ne seras plus visible par les autres membres'),
        findsOneWidget,
      );
      expect(
        find.text('Cette photo sera définitivement supprimée.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'supprimer une photo secondaire n\'affiche pas l\'avertissement de visibilité',
    (tester) async {
      final myProfile = FakeMyProfileRepository(
        fetchResult: Ok(
          fakeMyProfile(isVerified: true, photos: kPhotos),
        ),
      );
      await pumpPage(tester, myProfile: myProfile);

      final removeButtons = find.byTooltip('Retirer la photo');
      await tester.tap(removeButtons.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Cette photo sera définitivement supprimée.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Tu ne seras plus visible par les autres membres'),
        findsNothing,
      );
    },
  );
}
