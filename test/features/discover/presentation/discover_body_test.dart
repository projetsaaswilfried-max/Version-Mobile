import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/masking/discover_mask.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:agapeo/features/discover/presentation/discover_body.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_card.dart';
import 'package:agapeo/features/home/presentation/tabs/discover_tab_page.dart';
import 'package:agapeo/features/home/presentation/widgets/home_floating_nav_bar.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/profile_completeness.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/discover_test_fakes.dart';

void main() {
  Future<void> pumpDiscover(
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

  testWidgets('shows recommended and others sections', (tester) async {
    await pumpDiscover(
      tester,
      repo: FakeDiscoverRepository(
        candidates: Ok([
          fakeDiscoverProfile('a', displayName: 'Alice'),
          fakeDiscoverProfile('b', displayName: 'Béatrice'),
          fakeDiscoverProfile('c', displayName: 'Clara'),
          fakeDiscoverProfile('d', displayName: 'Diane'),
        ]),
      ),
    );

    expect(find.text('Recommandée pour vous'), findsOneWidget);
    expect(find.text('Autres profils'), findsOneWidget);
    expect(find.byType(DiscoverCard), findsNWidgets(4));
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Diane'), findsOneWidget);
    expect(find.text('Bientôt'), findsNothing);
  });

  testWidgets('masks identity when visitor cannot reveal', (tester) async {
    await pumpDiscover(
      tester,
      repo: FakeDiscoverRepository(
        visitor: const Ok(
          VisitorContext(
            id: 'visitor-1',
            gender: 'MALE',
            isVerified: false,
            subscriptionStatus: 'FREE',
            traits: CompatibilityTraits(),
          ),
        ),
        candidates: Ok([
          fakeDiscoverProfile('a', displayName: 'Léa', age: 28, city: 'Paris'),
        ]),
      ),
    );

    expect(find.text(maskIdentity('Léa')), findsOneWidget);
    expect(find.textContaining('**'), findsWidgets);
    expect(find.text('Léa'), findsNothing);
    expect(find.text('Paris'), findsNothing);
  });

  testWidgets('shows expired wall without cards', (tester) async {
    await pumpDiscover(
      tester,
      repo: FakeDiscoverRepository(
        visitor: const Ok(
          VisitorContext(
            id: 'visitor-1',
            gender: 'MALE',
            isVerified: true,
            subscriptionStatus: 'EXPIRED',
            traits: CompatibilityTraits(),
          ),
        ),
        candidates: Ok([fakeDiscoverProfile('a')]),
      ),
    );

    expect(find.text('Abonnement expiré'), findsOneWidget);
    expect(find.byType(DiscoverCard), findsNothing);
    expect(find.text('Recommandée pour vous'), findsNothing);
  });

  testWidgets('shows error and retries', (tester) async {
    final repo = FakeDiscoverRepository(
      visitor: const Err(NetworkFailure('offline')),
    );
    await pumpDiscover(tester, repo: repo);

    expect(find.text('Impossible de charger Découvrir'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    repo.visitor = const Ok(
      VisitorContext(
        id: 'visitor-1',
        gender: 'MALE',
        isVerified: true,
        subscriptionStatus: 'FREE',
        traits: CompatibilityTraits(),
      ),
    );
    repo.candidates = Ok([fakeDiscoverProfile('ok', displayName: 'Alice')]);
    await tester.tap(find.text('Réessayer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('Discover tab is not the Bientôt placeholder', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverRepositoryProvider.overrideWithValue(
            FakeDiscoverRepository(
              visitor: const Ok(
                VisitorContext(
                  id: 'visitor-1',
                  gender: 'MALE',
                  isVerified: true,
                  subscriptionStatus: 'ACTIVE',
                  traits: CompatibilityTraits(),
                ),
              ),
              candidates: Ok([fakeDiscoverProfile('a')]),
            ),
          ),
          profileCompletenessProvider.overrideWith(
            (ref) async =>
                const ProfileCompleteness(isComplete: true, missingKeys: []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DiscoverTabPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Découvrir'), findsOneWidget);
    expect(find.text('Bientôt'), findsNothing);
    expect(find.text('Recommandée pour vous'), findsOneWidget);
    final body = tester.widget<DiscoverBody>(find.byType(DiscoverBody));
    final tabContext = tester.element(find.byType(DiscoverTabPage));
    expect(body.bottomPadding, HomeFloatingNavBar.scrollClearance(tabContext));
  });

  testWidgets('shows premium sheet for FREE visitor after load', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoverRepositoryProvider.overrideWithValue(
            FakeDiscoverRepository(candidates: Ok([fakeDiscoverProfile('a')])),
          ),
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
    expect(find.text('Découvre tout Agapeo'), findsOneWidget);
    Navigator.of(tester.element(find.text('Découvre tout Agapeo'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Recommandée pour vous'), findsOneWidget);
  });
}
