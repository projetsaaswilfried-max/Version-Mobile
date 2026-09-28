import 'package:agapeo/core/config/debug_flags.dart';
import 'package:agapeo/core/error/failure.dart';
import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_search_field.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:agapeo/features/discover/presentation/discover_body.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_toolbar.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/profile_completeness.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/discover_test_fakes.dart';

Widget _wrap(DiscoverToolbar toolbar) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: toolbar));
}

void main() {
  testWidgets('locked search and filters call their own locked callback', (
    tester,
  ) async {
    var searchLocked = 0;
    var filtersLocked = 0;
    await tester.pumpWidget(
      _wrap(
        DiscoverToolbar(
          unlocked: false,
          onSearchLocked: () => searchLocked++,
          onFiltersLocked: () => filtersLocked++,
          onSearchTap: () {},
          onFiltersTap: () {},
        ),
      ),
    );

    await tester.tap(find.byTooltip('Passe Premium pour rechercher'));
    await tester.pump();
    expect(searchLocked, 1);
    expect(filtersLocked, 0);

    await tester.tap(find.byTooltip('Passe Premium pour filtrer'));
    await tester.pump();
    expect(filtersLocked, 1);
  });

  testWidgets('unlocked calls search and filters callbacks', (tester) async {
    var search = 0;
    var filters = 0;
    await tester.pumpWidget(
      _wrap(
        DiscoverToolbar(
          unlocked: true,
          onSearchLocked: () {},
          onFiltersLocked: () {},
          onSearchTap: () => search++,
          onFiltersTap: () => filters++,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pump();
    expect(search, 1);

    await tester.tap(find.byTooltip('Filtres'));
    await tester.pump();
    expect(filters, 1);
  });

  testWidgets('shows active filters badge and tooltip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        DiscoverToolbar(
          unlocked: true,
          filtersActive: true,
          onSearchLocked: () {},
          onFiltersLocked: () {},
          onSearchTap: () {},
          onFiltersTap: () {},
        ),
      ),
    );

    expect(find.byTooltip('Filtres actifs'), findsOneWidget);
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

  testWidgets('FREE Filtres tap opens premium sheet', (tester) async {
    await pumpDiscoverBody(
      tester,
      repo: FakeDiscoverRepository(candidates: Ok([fakeDiscoverProfile('a')])),
    );

    expect(find.text('Découvrir'), findsOneWidget);
    expect(find.byType(DiscoverToolbar), findsOneWidget);

    // Gate Premium court-circuitée en debug (voir `debug_flags.dart`).
    if (kBypassPremiumGatesForTesting) {
      expect(find.byTooltip('Filtres'), findsOneWidget);
      return;
    }

    expect(find.byTooltip('Passe Premium pour rechercher'), findsOneWidget);
    await tester.tap(find.byTooltip('Passe Premium pour filtrer'));
    await tester.pumpAndSettle();
    expect(find.text('Filtres avancés'), findsOneWidget);
    expect(find.text('Découvre tout Agapeo'), findsNothing);
  });

  testWidgets('empty list still shows locked toolbar', (tester) async {
    await pumpDiscoverBody(tester, repo: FakeDiscoverRepository());

    expect(find.text('Aucun profil pour le moment'), findsOneWidget);
    expect(find.byType(DiscoverToolbar), findsOneWidget);
  });

  testWidgets(
    'EXPIRED keeps the toolbar and shows cards, like FREE (D42)',
    (tester) async {
      await pumpDiscoverBody(
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

      expect(find.byType(DiscoverToolbar), findsOneWidget);
      expect(find.text('Abonnement expiré'), findsNothing);
    },
  );

  testWidgets('error hides toolbar', (tester) async {
    await pumpDiscoverBody(
      tester,
      repo: FakeDiscoverRepository(
        visitor: const Err(NetworkFailure('offline')),
      ),
    );

    expect(find.byType(DiscoverToolbar), findsNothing);
    expect(find.text('Impossible de charger Découvrir'), findsOneWidget);
  });

  testWidgets('ACTIVE filters opens sheet and apply filters by country', (
    tester,
  ) async {
    await pumpDiscoverBody(
      tester,
      repo: FakeDiscoverRepository(
        visitor: const Ok(
          VisitorContext(
            id: 'visitor-1',
            gender: 'MALE',
            isVerified: true,
            subscriptionStatus: 'ACTIVE',
            traits: CompatibilityTraits(),
          ),
        ),
        candidates: Ok([
          fakeDiscoverProfile(
            'a',
            displayName: 'Alice Martin',
            traits: const CompatibilityTraits(country: 'France'),
          ),
          fakeDiscoverProfile(
            'b',
            displayName: 'Béatrice Durand',
            traits: const CompatibilityTraits(country: 'Sénégal'),
          ),
        ]),
      ),
    );

    await tester.tap(find.byTooltip('Filtres'));
    await tester.pumpAndSettle();
    expect(find.text('Filtres : bientôt'), findsNothing);
    expect(find.text('Découvre tout Agapeo'), findsNothing);
    expect(find.text('Pays'), findsOneWidget);

    await tester.tap(find.text('Tous les pays'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AppSearchField),
        matching: find.byType(TextField),
      ),
      'Sén',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sénégal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect(find.text('Alice Martin'), findsNothing);
    expect(find.text('Béatrice Durand'), findsOneWidget);
  });
}
