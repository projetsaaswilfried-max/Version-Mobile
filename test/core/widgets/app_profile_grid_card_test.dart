import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_profile_grid_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));

  testWidgets('shows title, subtitle, and calls onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        AppProfileGridCard(
          title: 'Léa, 28',
          subtitle: 'Paris',
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Léa, 28'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);

    await tester.tap(find.byType(AppProfileGridCard));
    expect(tapped, isTrue);
  });

  testWidgets('hides the subtitle line when null or blank', (tester) async {
    await tester.pumpWidget(wrap(const AppProfileGridCard(title: 'Léa')));
    expect(find.text('Léa'), findsOneWidget);

    await tester.pumpWidget(
      wrap(const AppProfileGridCard(title: 'Léa', subtitle: '  ')),
    );
    await tester.pump();
    expect(find.text('  '), findsNothing);
  });

  testWidgets('shows a trailing widget when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppProfileGridCard(
          title: 'Léa',
          trailing: Icon(Icons.close, key: Key('trailing-icon')),
        ),
      ),
    );

    expect(find.byKey(const Key('trailing-icon')), findsOneWidget);
  });
}
