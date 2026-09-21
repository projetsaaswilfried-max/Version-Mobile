import 'dart:async';

import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_verified_badge.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:agapeo/features/discover/domain/entities/discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:agapeo/features/discover/domain/usecases/get_discover_profile_detail.dart';
import 'package:agapeo/features/discover/domain/usecases/is_discover_profile_favorited.dart';
import 'package:agapeo/features/discover/domain/usecases/is_discover_profile_liked.dart';
import 'package:agapeo/features/discover/domain/usecases/record_discover_profile_view.dart';
import 'package:agapeo/features/discover/presentation/discover_body.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_card.dart';
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
  spiritualEngagement: 'Pratique régulière',
  whyMarriage: 'Pour construire une famille.',
  values: ['Foi', 'Famille'],
  hobbies: ['Course'],
);

Future<void> _pumpSheet(
  WidgetTester tester, {
  required FakeDiscoverRepository repo,
  int scoreHint = 0,
  String profileId = 'p1',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getDiscoverProfileDetailProvider.overrideWithValue(
          GetDiscoverProfileDetail(repo),
        ),
        recordDiscoverProfileViewProvider.overrideWithValue(
          RecordDiscoverProfileView(repo),
        ),
        isDiscoverProfileLikedProvider.overrideWithValue(
          IsDiscoverProfileLiked(repo),
        ),
        isDiscoverProfileFavoritedProvider.overrideWithValue(
          IsDiscoverProfileFavorited(repo),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverProfileSheet(
            profileId: profileId,
            scoreHint: scoreHint,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('loading then success records view and shows profile', (
    tester,
  ) async {
    final pending = Completer<Result<DiscoverProfileDetail>>();
    final repo = FakeDiscoverRepository(pendingDetail: pending);

    await _pumpSheet(tester, repo: repo);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(const Ok(_detail));
    await tester.pump();
    await tester.pump();

    expect(find.text('Léa Martin'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.text(' (28)'), findsOneWidget);
    expect(find.byTooltip('Fermer'), findsOneWidget);
    expect(find.text('Score 42'), findsOneWidget);
    expect(find.text('Protestante'), findsOneWidget);
    expect(find.text('Pratique régulière'), findsOneWidget);
    expect(find.text('Pour construire une famille.'), findsOneWidget);
    expect(find.text('Foi'), findsWidgets);
    expect(find.text('Famille'), findsOneWidget);
    expect(find.text('Course'), findsOneWidget);
    expect(repo.fetchDetailIds, ['p1']);
    expect(repo.recordViewIds, ['p1']);
  });

  testWidgets('error shows retry then loads on tap', (tester) async {
    final repo = FakeDiscoverRepository(
      detail: const Err(ServerFailure('Profil introuvable.')),
    );
    await _pumpSheet(tester, repo: repo);
    await tester.pump();

    expect(find.text('Profil introuvable.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
    expect(repo.recordViewIds, isEmpty);

    repo.detail = const Ok(_detail);
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Léa Martin'), findsOneWidget);
    expect(repo.recordViewIds, ['p1']);
  });

  testWidgets('record error still shows profile', (tester) async {
    final repo = FakeDiscoverRepository(
      detail: const Ok(_detail),
      recordView: const Err(ServerFailure('rpc down')),
    );
    await _pumpSheet(tester, repo: repo);
    await tester.pump();

    expect(find.text('Léa Martin'), findsOneWidget);
    expect(repo.recordViewIds, ['p1']);
  });

  testWidgets('scoreHint applies when detail score is 0', (tester) async {
    final repo = FakeDiscoverRepository(
      detail: const Ok(
        DiscoverProfileDetail(id: 'p1', displayName: 'Léa Martin', score: 0),
      ),
    );
    await _pumpSheet(tester, repo: repo, scoreHint: 17);
    await tester.pump();

    expect(find.text('Score 17'), findsOneWidget);
    expect(find.text('Confession'), findsNothing);
    expect(find.text('Engagement spirituel'), findsNothing);
    expect(find.text('Pourquoi le mariage'), findsNothing);
    expect(find.text('Valeurs'), findsNothing);
    expect(find.text('Loisirs'), findsNothing);
  });

  testWidgets('Favori without canFavorite opens verify sheet', (tester) async {
    final repo = FakeDiscoverRepository(detail: const Ok(_detail));
    await _pumpSheet(tester, repo: repo);
    await tester.pump();

    await tester.tap(find.byTooltip('Favori'));
    await tester.pumpAndSettle();
    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(find.text('Favori : bientôt'), findsNothing);
  });

  testWidgets('DiscoverCard onTap fires when provided', (tester) async {
    var taps = 0;
    tester.view.physicalSize = const Size(400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DiscoverCard(
              profile: fakeDiscoverProfile('a'),
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    await tester.tap(find.byType(DiscoverCard));
    await tester.pump();
    expect(taps, 1);
    expect(find.text('Léa Martin'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.byType(AppVerifiedBadge), findsOneWidget);
  });

  testWidgets('DiscoverCard more opens Signaler and Bloquer sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DiscoverCard(profile: fakeDiscoverProfile('a')),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Signaler ou bloquer'));
    await tester.pumpAndSettle();
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Signaler'), findsOneWidget);
    expect(find.text('Bloquer'), findsOneWidget);
  });

  Future<void> pumpDiscoverBody(
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
    if (find.text('Découvre tout Agapeo').evaluate().isNotEmpty) {
      Navigator.of(tester.element(find.text('Découvre tout Agapeo'))).pop();
      await tester.pumpAndSettle();
    }
  }

  testWidgets('unverified tap card opens verify sheet', (tester) async {
    final repo = FakeDiscoverRepository(
      visitor: const Ok(
        VisitorContext(
          id: 'visitor-1',
          gender: 'MALE',
          isVerified: false,
          subscriptionStatus: 'FREE',
          traits: CompatibilityTraits(),
        ),
      ),
      candidates: Ok([fakeDiscoverProfile('a')]),
    );
    await pumpDiscoverBody(tester, repo: repo);

    await tester.tap(find.byKey(const ValueKey('discover-card-a')));
    await tester.pumpAndSettle();
    expect(find.text('Valide ton profil'), findsOneWidget);
    expect(find.text('Protestante'), findsNothing);
    expect(repo.fetchDetailIds, isEmpty);
  });

  testWidgets('FREE verified tap card opens profile sheet', (tester) async {
    // Ouvrir une fiche est débloqué par la vérification seule, pas
    // l'abonnement (Q1, docs/decisions.md) — visiteur FREE mais vérifié.
    final repo = FakeDiscoverRepository(
      candidates: Ok([fakeDiscoverProfile('a')]),
      detail: const Ok(_detail),
    );
    await pumpDiscoverBody(tester, repo: repo);

    await tester.tap(find.byKey(const ValueKey('discover-card-a')));
    await tester.pumpAndSettle();
    expect(find.text('Protestante'), findsOneWidget);
    expect(find.text('Découvre tout Agapeo'), findsNothing);
    expect(repo.fetchDetailIds, ['a']);
  });

  testWidgets('ACTIVE tap card opens profile sheet', (tester) async {
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
      candidates: Ok([fakeDiscoverProfile('a', displayName: 'Alice')]),
      detail: const Ok(_detail),
    );
    await pumpDiscoverBody(tester, repo: repo);

    await tester.tap(find.byKey(const ValueKey('discover-card-a')));
    await tester.pumpAndSettle();

    expect(find.text('Protestante'), findsOneWidget);
    expect(find.byTooltip('Fermer'), findsOneWidget);
    expect(find.text('Découvre tout Agapeo'), findsNothing);
    expect(repo.fetchDetailIds, ['a']);
  });
}
