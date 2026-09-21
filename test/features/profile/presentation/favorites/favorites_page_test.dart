import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/domain/entities/account_person.dart';
import 'package:agapeo/features/profile/presentation/favorites/favorites_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/profile_account_test_fakes.dart';

void main() {
  testWidgets('liste les favoris sans erreur de colonne', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(
              favorites: const [
                AccountPerson(
                  id: '2',
                  displayName: 'Marc Dupont',
                  city: 'Lyon',
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const FavoritesPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Marc Dupont'), findsOneWidget);
    expect(find.textContaining('does not exist'), findsNothing);
    expect(find.textContaining('target_id'), findsNothing);
  });

  Future<FakeProfileAccountRepository> pumpWithOneFavorite(
    WidgetTester tester,
  ) async {
    final repo = FakeProfileAccountRepository(
      favorites: const [
        AccountPerson(id: '2', displayName: 'Marc Dupont', city: 'Lyon'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileAccountRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const FavoritesPage()),
      ),
    );
    await tester.pump();
    await tester.pump();
    return repo;
  }

  testWidgets('retirer un favori demande confirmation en bottom sheet', (
    tester,
  ) async {
    final repo = await pumpWithOneFavorite(tester);

    await tester.tap(find.byTooltip('Retirer des favoris'));
    await tester.pumpAndSettle();

    expect(find.text('Retirer des favoris ?'), findsOneWidget);
    expect(repo.lastRemovedFavorite, isNull);
    expect(find.text('Marc Dupont'), findsOneWidget);
  });

  testWidgets('annuler la confirmation ne retire pas le favori', (
    tester,
  ) async {
    final repo = await pumpWithOneFavorite(tester);

    await tester.tap(find.byTooltip('Retirer des favoris'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(repo.lastRemovedFavorite, isNull);
    expect(find.text('Marc Dupont'), findsOneWidget);
  });

  testWidgets('confirmer retire bien le favori', (tester) async {
    final repo = await pumpWithOneFavorite(tester);

    await tester.tap(find.byTooltip('Retirer des favoris'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();

    expect(repo.lastRemovedFavorite, '2');
    expect(find.text('Marc Dupont'), findsNothing);
  });
}
