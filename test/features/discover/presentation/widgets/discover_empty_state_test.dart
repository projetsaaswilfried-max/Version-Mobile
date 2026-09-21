import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('default empty has no clear action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: DiscoverEmptyState()),
      ),
    );

    expect(find.text('Aucun profil pour le moment'), findsOneWidget);
    expect(find.text('Effacer les filtres'), findsNothing);
  });

  testWidgets('filtered empty offers clear filters', (tester) async {
    var cleared = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverEmptyState(
            hasActiveFilters: true,
            onClearFilters: () => cleared++,
          ),
        ),
      ),
    );

    expect(find.text('Aucun profil ne correspond'), findsOneWidget);
    await tester.tap(find.text('Effacer les filtres'));
    await tester.pump();
    expect(cleared, 1);
  });
}
