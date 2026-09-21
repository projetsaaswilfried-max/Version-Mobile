import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/discover/presentation/widgets/discover_premium_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('premium sheet shows title plans and dismiss', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DiscoverPremiumSheet(onDismiss: () => dismissed = true),
        ),
      ),
    );

    expect(find.text('Découvre tout Agapeo'), findsOneWidget);
    expect(find.text('1 semaine'), findsOneWidget);
    expect(find.text('2 335 FCFA'), findsOneWidget);
    expect(find.text('Quitter maintenant'), findsOneWidget);

    await tester.tap(find.text('Quitter maintenant'));
    expect(dismissed, isTrue);
  });
}
