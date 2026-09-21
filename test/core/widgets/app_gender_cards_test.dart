import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_gender_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tapping Homme selects man id', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppGenderCards(
            selectedId: selected,
            onSelected: (id) => selected = id,
          ),
        ),
      ),
    );

    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.text('Homme'));
    await tester.pump();
    expect(selected, 'man');
    expect(find.text('Autre'), findsNothing);
  });
}
