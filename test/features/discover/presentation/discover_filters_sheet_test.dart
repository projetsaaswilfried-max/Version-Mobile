import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/discover/domain/entities/discover_query.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sheet exposes three fields and actions', (tester) async {
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

    expect(find.text('Ville'), findsOneWidget);
    expect(find.text('Dénomination'), findsOneWidget);
    expect(find.text('Profession'), findsOneWidget);
    expect(find.text('Appliquer'), findsOneWidget);
    expect(find.text('Réinitialiser'), findsOneWidget);
    expect(find.text('Fermer'), findsOneWidget);
  });

  testWidgets('Appliquer sends trimmed field values', (tester) async {
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
      ' Lyon ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('discover-filter-denomination')),
      'Catho',
    );
    await tester.tap(find.text('Appliquer'));
    await tester.pump();

    expect(applied?.city, 'Lyon');
    expect(applied?.denomination, 'Catho');
    expect(applied?.profession, isNull);
  });

  testWidgets('Réinitialiser calls onReset', (tester) async {
    var reset = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverFiltersSheet(
            initialQuery: const DiscoverQuery(city: 'Paris'),
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
}
