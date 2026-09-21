import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_profile_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('identity shows name, age, city and verified', (tester) async {
    await tester.pumpWidget(
      wrap(
        const AppProfileIdentity(
          displayName: 'Léa Martin',
          ageLabel: '28',
          city: 'Paris',
          isVerified: true,
        ),
      ),
    );

    expect(find.text('Léa Martin'), findsOneWidget);
    expect(find.text(' (28)'), findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
    expect(find.bySemanticsLabel('Vérifié'), findsOneWidget);
  });

  testWidgets('section shows title', (tester) async {
    await tester.pumpWidget(
      wrap(const AppProfileSection(title: 'À propos', child: Text('Bio'))),
    );

    expect(find.text('À propos'), findsOneWidget);
    expect(find.text('Bio'), findsOneWidget);
  });
}
