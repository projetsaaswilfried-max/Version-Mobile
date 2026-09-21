import 'package:agapeo/core/error/result.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_profile_grid_card.dart';
import 'package:agapeo/features/discover/di/discover_providers.dart';
import 'package:agapeo/features/discover/domain/entities/visitor_context.dart';
import 'package:agapeo/features/discover/domain/scoring/compatibility_traits.dart';
import 'package:agapeo/features/discover/presentation/discover_controller.dart';
import 'package:agapeo/features/discover/presentation/search/discover_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/discover_test_fakes.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FakeDiscoverRepository repo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DiscoverSearchPage(),
                  ),
                ),
                child: const Text('Ouvrir la recherche'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir la recherche'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a prompt before any search is submitted', (
    tester,
  ) async {
    await _pump(tester, repo: FakeDiscoverRepository());

    expect(find.text('Recherche un profil'), findsOneWidget);
  });

  testWidgets(
    'submitting a search finds a profile beyond the already-loaded pool',
    (tester) async {
      final repo = FakeDiscoverRepository(
        candidates: Ok([
          fakeDiscoverProfile('p01', displayName: 'Alice'),
          fakeDiscoverProfile('p02', displayName: 'Béatrice'),
        ]),
      );
      await _pump(tester, repo: repo);

      // "Luc" arrive côté serveur après le chargement initial de la page —
      // exactement le scénario remonté en test manuel.
      repo.candidates = Ok([
        fakeDiscoverProfile('p01', displayName: 'Alice'),
        fakeDiscoverProfile('p02', displayName: 'Béatrice'),
        fakeDiscoverProfile('p99', displayName: 'Luc'),
      ]);

      await tester.enterText(find.byType(TextField), 'Luc');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppProfileGridCard, 'Luc'), findsOneWidget);
      expect(
        find.widgetWithText(AppProfileGridCard, 'Alice'),
        findsNothing,
      );
    },
  );

  testWidgets('no match shows the not-found empty state', (tester) async {
    final repo = FakeDiscoverRepository(
      candidates: Ok([fakeDiscoverProfile('p01', displayName: 'Alice')]),
    );
    await _pump(tester, repo: repo);

    await tester.enterText(find.byType(TextField), 'Zzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Aucun profil trouvé'), findsOneWidget);
  });

  testWidgets('clear button resets the search and the query', (tester) async {
    final repo = FakeDiscoverRepository(
      candidates: Ok([fakeDiscoverProfile('p01', displayName: 'Alice')]),
    );
    await _pump(tester, repo: repo);

    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppProfileGridCard, 'Alice'), findsOneWidget);

    await tester.tap(find.byTooltip('Effacer'));
    await tester.pumpAndSettle();

    expect(find.text('Recherche un profil'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('back button restores the shared feed for the page below', (
    tester,
  ) async {
    final repo = FakeDiscoverRepository(
      visitor: const Ok(
        VisitorContext(
          id: 'visitor-1',
          gender: 'MALE',
          isVerified: true,
          subscriptionStatus: 'FREE',
          traits: CompatibilityTraits(),
        ),
      ),
      candidates: Ok([fakeDiscoverProfile('p01', displayName: 'Alice')]),
    );
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [discoverRepositoryProvider.overrideWithValue(repo)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DiscoverSearchPage(),
                      ),
                    ),
                    child: const Text('Ouvrir la recherche'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir la recherche'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Alice');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(container.read(discoverControllerProvider).query.isEmpty, isFalse);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    expect(container.read(discoverControllerProvider).query.isEmpty, isTrue);
  });
}
