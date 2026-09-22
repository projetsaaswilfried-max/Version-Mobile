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
import 'package:agapeo/features/discover/domain/usecases/send_discover_invitation.dart';
import 'package:agapeo/features/discover/domain/usecases/unfavorite_discover_profile.dart';
import 'package:agapeo/features/discover/domain/usecases/unlike_discover_profile.dart';
import 'package:agapeo/features/discover/presentation/discover_body.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_invite_sheet.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_profile_sheet.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/profile_completeness.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/discover_test_fakes.dart';

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
    sendDiscoverInvitationProvider.overrideWithValue(
      SendDiscoverInvitation(repo),
    ),
  ];
}

Future<void> _pumpInviteSheet(
  WidgetTester tester, {
  required FakeDiscoverRepository repo,
  VoidCallback? onDismiss,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: _sheetOverrides(repo),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverInviteSheet(
            profileId: 'p1',
            displayName: 'Léa Martin',
            onDismiss: onDismiss,
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpProfileSheet(
  WidgetTester tester, {
  required FakeDiscoverRepository repo,
  bool canInvite = true,
  String subscriptionStatus = 'ACTIVE',
  bool visitorIsStaff = false,
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
            canInvite: canInvite,
            subscriptionStatus: subscriptionStatus,
            visitorIsStaff: visitorIsStaff,
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
  testWidgets('invite sheet shows name, message field and actions', (
    tester,
  ) async {
    var dismissed = false;
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpInviteSheet(
      tester,
      repo: repo,
      onDismiss: () => dismissed = true,
    );

    expect(find.text('Léa Martin'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    expect(dismissed, isTrue);
    expect(repo.sendInvitationCalls, isEmpty);
  });

  testWidgets('Envoyer sends optional message then pops with snackbar', (
    tester,
  ) async {
    var dismissed = false;
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpInviteSheet(
      tester,
      repo: repo,
      onDismiss: () => dismissed = true,
    );

    await tester.enterText(find.byType(TextField), 'Bonjour Léa');
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(repo.sendInvitationCalls, [
      (profileId: 'p1', message: 'Bonjour Léa'),
    ]);
    expect(dismissed, isTrue);
    expect(find.text('Invitation envoyée'), findsOneWidget);
  });

  testWidgets('Envoyer without message sends null', (tester) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpInviteSheet(tester, repo: repo, onDismiss: () {});

    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(repo.sendInvitationCalls, [(profileId: 'p1', message: null)]);
  });

  testWidgets('Envoyer Err shows failure snackbar and stays open', (
    tester,
  ) async {
    var dismissed = false;
    final repo = FakeDiscoverRepository(detail: const Ok(_detail))
      ..sendInvitationResult = const Err(ServerFailure('Quota atteint.'));
    await _pumpInviteSheet(
      tester,
      repo: repo,
      onDismiss: () => dismissed = true,
    );

    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(dismissed, isFalse);
    expect(find.text('Quota atteint.'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
  });

  testWidgets('!canInvite on Inviter opens Valide ton profil', (tester) async {
    var verifyCalled = false;
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpProfileSheet(
      tester,
      repo: repo,
      canInvite: false,
      onVerifyProfile: () => verifyCalled = true,
    );

    await tester.tap(find.byTooltip('Envoyer un message'));
    await tester.pumpAndSettle();

    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(repo.sendInvitationCalls, isEmpty);

    await tester.tap(find.text('Vérifier mon profil'));
    await tester.pumpAndSettle();
    expect(verifyCalled, isTrue);
  });

  testWidgets('FREE Inviter opens targeted premium sheet (D29)', (
    tester,
  ) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpProfileSheet(tester, repo: repo, subscriptionStatus: 'FREE');

    await tester.tap(find.byTooltip('Envoyer un message'));
    await tester.pumpAndSettle();

    expect(find.text('Envoyer une invitation'), findsOneWidget);
    expect(find.text('Découvre tout Agapeo'), findsNothing);
    expect(find.text('Envoyer'), findsNothing);
    expect(repo.sendInvitationCalls, isEmpty);
  });

  testWidgets('canInvite opens invite sheet with display name', (tester) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpProfileSheet(tester, repo: repo);

    await tester.tap(find.byTooltip('Envoyer un message'));
    await tester.pumpAndSettle();

    expect(find.text('Envoyer'), findsOneWidget);
    expect(find.text('Léa Martin'), findsWidgets);
  });

  testWidgets('Favori without canFavorite opens verify sheet', (tester) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpProfileSheet(tester, repo: repo);

    await tester.tap(find.byTooltip('Favori'));
    await tester.pumpAndSettle();
    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(find.text('Favori : bientôt'), findsNothing);
  });

  testWidgets('body unverified Inviter opens verify sheet', (tester) async {
    expect(canInviteDiscoverProfile(visitorVerified: false), isFalse);
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
    // le tap sur la carte, avant même d'atteindre le bouton Inviter.
    await tester.tap(find.byKey(const ValueKey('discover-card-p1')));
    await tester.pumpAndSettle();

    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(repo.sendInvitationCalls, isEmpty);
  });

  testWidgets('body verified ACTIVE Inviter opens invite sheet', (
    tester,
  ) async {
    final repo = FakeDiscoverRepository(
      visitor: const Ok(
        VisitorContext(
          id: 'visitor-1',
          gender: 'MALE',
          isVerified: true,
          subscriptionStatus: 'ACTIVE',
          traits: CompatibilityTraits(),
        ),
      ),
      candidates: Ok([fakeDiscoverProfile('p1')]),
      detail: const Ok(_detail),
    );

    await _pumpDiscoverBody(tester, repo: repo);
    await tester.tap(find.byKey(const ValueKey('discover-card-p1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Envoyer un message'));
    await tester.pumpAndSettle();

    expect(find.text('Envoyer'), findsOneWidget);
    expect(find.text('Valide ton profil'), findsNothing);
  });
}
