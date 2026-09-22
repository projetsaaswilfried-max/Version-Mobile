import 'package:agapeo/core/config/church_denominations.dart';
import 'package:agapeo/core/config/countries.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_search_field.dart';
import 'package:agapeo/features/discover/domain/entities/discover_query.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'sheet exposes age, country, city, profession, marital and confession filters',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DiscoverFiltersSheet(
              onApply: (_) {},
              onReset: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Filtres'), findsOneWidget);
      expect(find.text('Âge'), findsOneWidget);
      expect(find.text('Pays'), findsOneWidget);
      expect(find.text('Ville'), findsOneWidget);
      expect(find.text('Profession'), findsOneWidget);
      expect(find.text('Situation matrimoniale'), findsOneWidget);
      expect(find.text('Confession'), findsOneWidget);
      expect(find.text('Réinitialiser'), findsOneWidget);
      expect(find.text('Appliquer'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);
      expect(find.text('Célibataire sans enfant'), findsOneWidget);
      await tester.ensureVisible(find.text(churchDenominations.first));
      expect(find.text(churchDenominations.first), findsOneWidget);
      expect(find.text('Tous les pays'), findsOneWidget);
    },
  );

  testWidgets('Appliquer sends selected closed-list values', (tester) async {
    DiscoverQuery? applied;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverFiltersSheet(
            onApply: (query) => applied = query,
            onReset: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Célibataire sans enfant'));
    await tester.tap(find.text('Célibataire sans enfant'));
    await tester.pump();
    await tester.ensureVisible(find.text('Catholique'));
    await tester.tap(find.text('Catholique'));
    await tester.pump();
    await tester.ensureVisible(find.text('Appliquer'));
    await tester.tap(find.text('Appliquer'));
    await tester.pump();

    expect(applied?.maritalStatuses, ['SINGLE_NO_CHILDREN']);
    expect(applied?.denominations, ['Catholique']);
    expect(applied?.country, isNull);
    expect(applied?.ageMin, isNull);
    expect(applied?.ageMax, isNull);
  });

  testWidgets('country picker uses the onboarding list', (tester) async {
    DiscoverQuery? applied;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverFiltersSheet(
            onApply: (query) => applied = query,
            onReset: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

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
    expect(kOnboardingCountries, contains('Sénégal'));
    await tester.tap(find.text('Sénégal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appliquer'));
    await tester.pump();

    expect(applied?.country, 'Sénégal');
  });

  testWidgets('Appliquer sends city and profession free text', (
    tester,
  ) async {
    DiscoverQuery? applied;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverFiltersSheet(
            onApply: (query) => applied = query,
            onReset: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('discover-filter-city')),
      'Dakar',
    );
    await tester.enterText(
      find.byKey(const ValueKey('discover-filter-profession')),
      'Ingénieure',
    );
    await tester.ensureVisible(find.text('Appliquer'));
    await tester.tap(find.text('Appliquer'));
    await tester.pump();

    expect(applied?.city, 'Dakar');
    expect(applied?.profession, 'Ingénieure');
  });

  testWidgets('Réinitialiser calls onReset', (tester) async {
    var reset = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverFiltersSheet(
            initialQuery: const DiscoverQuery(country: 'France'),
            onApply: (_) {},
            onReset: () => reset++,
            onDismiss: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Réinitialiser'));
    await tester.pump();
    expect(reset, 1);
  });

  testWidgets('initial age range is shown in the header', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverFiltersSheet(
            initialQuery: const DiscoverQuery(ageMin: 28, ageMax: 48),
            onApply: (_) {},
            onReset: () {},
            onDismiss: () {},
          ),
        ),
      ),
    );

    expect(find.text('28 - 48'), findsOneWidget);
  });
}
