import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/premium/discover_premium_gate.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:agapeo/features/discover/domain/usecases/favorite_discover_profile.dart';
import 'package:agapeo/features/discover/domain/usecases/get_discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/usecases/is_discover_profile_favorited.dart';
import 'package:agapeo/features/discover/domain/usecases/is_discover_profile_liked.dart';
import 'package:agapeo/features/discover/domain/usecases/like_discover_profile.dart';
import 'package:agapeo/features/discover/domain/usecases/record_discover_profile_view.dart';
import 'package:agapeo/features/discover/domain/usecases/unfavorite_discover_profile.dart';
import 'package:agapeo/features/discover/domain/usecases/unlike_discover_profile.dart';
import 'package:agapeo/features/discover/presentation/discover_body.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_profile_sheet.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/presentation/security/add_profile_photo_page.dart';
import 'package:agapeo/features/profile/domain/entities/profile_completeness.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/discover_test_fakes.dart';
import '../../../helpers/profile_account_test_fakes.dart';
import '../../../helpers/profile_test_fakes.dart';

const _detail = DiscoverProfileDetail(
  id: 'p1',
  displayName: 'Léa Martin',
  age: 28,
  city: 'Paris',
  isVerified: true,
  score: 42,
  confession: 'Protestante',
);

_sheetOverrides(FakeDiscoverRepository repo) {
  return [
    getDiscoverProfileDetailProvider.overrideWithValue(
      GetDiscoverProfileDetail(repo),
    ),
    recordDiscoverProfileViewProvider.overrideWithValue(
      RecordDiscoverProfileView(repo),
    ),
    isDiscoverProfileLikedProvider.overrideWithValue(
      IsDiscoverProfileLiked(repo),
    ),
    likeDiscoverProfileProvider.overrideWithValue(LikeDiscoverProfile(repo)),
    unlikeDiscoverProfileProvider.overrideWithValue(
      UnlikeDiscoverProfile(repo),
    ),
    isDiscoverProfileFavoritedProvider.overrideWithValue(
      IsDiscoverProfileFavorited(repo),
    ),
    favoriteDiscoverProfileProvider.overrideWithValue(
      FavoriteDiscoverProfile(repo),
    ),
    myProfileRepositoryProvider.overrideWithValue(FakeMyProfileRepository()),
    unfavoriteDiscoverProfileProvider.overrideWithValue(
      UnfavoriteDiscoverProfile(repo),
    ),
  ];
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required FakeDiscoverRepository repo,
  bool canFavorite = true,
  bool visitorVerified = true,
  VoidCallback? onVerifyProfile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _sheetOverrides(repo),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverProfileSheet(
            profileId: 'p1',
            canFavorite: canFavorite,
            visitorVerified: visitorVerified,
            onVerifyProfile: onVerifyProfile,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpDiscoverBody(
  WidgetTester tester, {
  required FakeDiscoverRepository repo,
}) async {
  tester.view.physicalSize = const Size(400, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoverRepositoryProvider.overrideWithValue(repo),
        profileCompletenessProvider.overrideWith(
          (ref) async =>
              const ProfileCompleteness(isComplete: true, missingKeys: []),
        ),
        profileAccountRepositoryProvider.overrideWithValue(
          FakeProfileAccountRepository(),
        ),
        myProfileRepositoryProvider.overrideWithValue(
          FakeMyProfileRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: DiscoverBody()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets(
    '!verified Favori opens Valide ton profil without writing',
    (tester) async {
      var verifyCalled = false;
      final repo = FakeDiscoverRepository(detail: const Ok(_detail));
      await _pumpSheet(
        tester,
        repo: repo,
        canFavorite: false,
        visitorVerified: false,
        onVerifyProfile: () => verifyCalled = true,
      );

      expect(repo.isFavoritedIds, ['p1']);
      expect(find.byIcon(Icons.star_border), findsOneWidget);

      await tester.tap(find.byTooltip('Favori'));
      await tester.pumpAndSettle();

      expect(find.text('Valide ton profil'), findsOneWidget);
      expect(find.text('Découvre tout Agapeo'), findsNothing);
      expect(repo.favoriteIds, isEmpty);
      expect(repo.unfavoriteIds, isEmpty);

      await tester.tap(find.text('Vérifier mon profil'));
      await tester.pumpAndSettle();
      expect(verifyCalled, isTrue);
    },
  );

  testWidgets(
    'verified !ACTIVE Favori opens Premium without writing',
    (tester) async {
      final repo = FakeDiscoverRepository(detail: const Ok(_detail));
      await _pumpSheet(
        tester,
        repo: repo,
        canFavorite: false,
        visitorVerified: true,
      );

      await tester.tap(find.byTooltip('Favori'));
      await tester.pumpAndSettle();

      expect(find.text('Découvre tout Agapeo'), findsOneWidget);
      expect(find.text('Valide ton profil'), findsNothing);
      expect(repo.favoriteIds, isEmpty);
      expect(repo.unfavoriteIds, isEmpty);
    },
  );

  testWidgets('canFavorite toggles favorite then unfavorite and fills icon', (
    tester,
  ) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpSheet(tester, repo: repo);

    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);

    await tester.tap(find.byTooltip('Favori'));
    await tester.pumpAndSettle();

    expect(repo.favoriteIds, ['p1']);
    expect(repo.unfavoriteIds, isEmpty);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.text('Valide ton profil'), findsNothing);
    expect(find.text('Découvre tout Agapeo'), findsNothing);

    await tester.tap(find.byTooltip('Favori'));
    await tester.pumpAndSettle();

    expect(repo.unfavoriteIds, ['p1']);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  testWidgets('already favorited loads filled icon then unfavorite', (
    tester,
  ) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail))
      ..isFavorited = const Ok(true);
    await _pumpSheet(tester, repo: repo);

    expect(find.byIcon(Icons.star), findsOneWidget);

    await tester.tap(find.byTooltip('Favori'));
    await tester.pumpAndSettle();

    expect(repo.favoriteIds, isEmpty);
    expect(repo.unfavoriteIds, ['p1']);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  testWidgets('favorite error shows failure snackbar and keeps outline', (
    tester,
  ) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail))
      ..favorite = const Err(ServerFailure('Impossible de mettre en favori'));
    await _pumpSheet(tester, repo: repo);

    await tester.tap(find.byTooltip('Favori'));
    await tester.pumpAndSettle();

    expect(find.text('Impossible de mettre en favori'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('body unverified Favori opens verify then D04 snackbar', (
    tester,
  ) async {
    expect(canFavoriteDiscoverProfile(visitorVerified: false), isFalse);

    final repo = FakeDiscoverRepository(
      visitor: const Ok(
        VisitorContext(
          id: 'visitor-1',
          gender: 'MALE',
          isVerified: false,
          subscriptionStatus: 'ACTIVE',
          traits: CompatibilityTraits(),
        ),
      ),
      candidates: Ok([fakeDiscoverProfile('p1')]),
      detail: const Ok(_detail),
    );

    await _pumpDiscoverBody(tester, repo: repo);

    // Non vérifié : ouvrir la fiche est déjà gaté par la vérification seule
    // (Q1, docs/decisions.md), donc le sheet de vérification apparaît dès
    // le tap sur la carte, avant même d'atteindre le bouton Favori.
    await tester.tap(find.byKey(const ValueKey('discover-card-p1')));
    await tester.pumpAndSettle();
    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(repo.favoriteIds, isEmpty);

    await tester.tap(find.text('Vérifier mon profil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AddProfilePhotoPage), findsOneWidget);
  });
}
