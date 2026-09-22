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
import 'package:agapeo/features/discover/presentation/widgets/discover_verify_sheet.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/presentation/security/verification_page.dart';
import 'package:agapeo/features/profile/domain/entities/profile_completeness.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/discover_test_fakes.dart';
import '../../../helpers/profile_account_test_fakes.dart';

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
    unfavoriteDiscoverProfileProvider.overrideWithValue(
      UnfavoriteDiscoverProfile(repo),
    ),
  ];
}

Finder _likeIcon(IconData icon) => find.descendant(
  of: find.byTooltip('Like'),
  matching: find.byIcon(icon),
);

Future<void> _pumpSheet(
  WidgetTester tester, {
  required FakeDiscoverRepository repo,
  bool canLike = true,
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
            canLike: canLike,
            onVerifyProfile: onVerifyProfile,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('verify sheet shows title body and actions', (tester) async {
    var dismissed = false;
    var verified = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverVerifySheet(
            onDismiss: () => dismissed = true,
            onVerify: () => verified = true,
          ),
        ),
      ),
    );

    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(find.textContaining("valide d'abord ton identité"), findsOneWidget);

    await tester.tap(find.text('Vérifier mon profil'));
    expect(verified, isTrue);

    await tester.tap(find.text('Fermer'));
    expect(dismissed, isTrue);
  });

  testWidgets('!canLike on Like opens Valide ton profil without writing', (
    tester,
  ) async {
    var verifyCalled = false;
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpSheet(
      tester,
      repo: repo,
      canLike: false,
      onVerifyProfile: () => verifyCalled = true,
    );

    expect(repo.isLikedIds, ['p1']);
    expect(_likeIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle();

    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(repo.likeIds, isEmpty);
    expect(repo.unlikeIds, isEmpty);

    await tester.tap(find.text('Vérifier mon profil'));
    await tester.pumpAndSettle();
    expect(verifyCalled, isTrue);
  });

  testWidgets('canLike toggles like then unlike and fills icon', (
    tester,
  ) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpSheet(tester, repo: repo);

    expect(_likeIcon(Icons.favorite_border), findsOneWidget);
    expect(_likeIcon(Icons.favorite), findsNothing);

    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle();

    expect(repo.likeIds, ['p1']);
    expect(repo.unlikeIds, isEmpty);
    expect(_likeIcon(Icons.favorite), findsOneWidget);
    expect(find.text('Valide ton profil'), findsNothing);

    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle();

    expect(repo.unlikeIds, ['p1']);
    expect(_likeIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('already liked loads filled icon then unlike', (tester) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail))
      ..isLiked = const Ok(true);
    await _pumpSheet(tester, repo: repo);

    expect(_likeIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle();

    expect(repo.likeIds, isEmpty);
    expect(repo.unlikeIds, ['p1']);
    expect(_likeIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('like error shows failure snackbar and keeps outline', (
    tester,
  ) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail))
      ..like = const Err(ServerFailure("Impossible d'aimer ce profil"));
    await _pumpSheet(tester, repo: repo);

    await tester.tap(find.byTooltip('Like'));
    await tester.pumpAndSettle();

    expect(find.text("Impossible d'aimer ce profil"), findsOneWidget);
    expect(_likeIcon(Icons.favorite_border), findsOneWidget);
    expect(_likeIcon(Icons.favorite), findsNothing);
  });

  testWidgets('Favori without canFavorite opens verify sheet', (tester) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpSheet(tester, repo: repo);

    await tester.tap(find.byTooltip('Favori'));
    await tester.pumpAndSettle();
    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(find.text('Favori : bientôt'), findsNothing);
  });

  testWidgets('unverified ACTIVE tap card opens verify then D04 snackbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    expect(canLikeDiscoverProfile(visitorVerified: false), isFalse);

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
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: DiscoverBody()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Non vérifié : ouvrir la fiche est déjà gaté par la vérification seule
    // (Q1, docs/decisions.md), donc le sheet de vérification apparaît dès
    // le tap sur la carte, avant même d'atteindre le bouton Like.
    await tester.tap(find.byKey(const ValueKey('discover-card-p1')));
    await tester.pumpAndSettle();
    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(repo.likeIds, isEmpty);
    expect(repo.fetchDetailIds, isEmpty);

    await tester.tap(find.text('Vérifier mon profil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(VerificationPage), findsOneWidget);
  });
}
