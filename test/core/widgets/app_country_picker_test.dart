import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selects country from searchable sheet', (tester) async {
    String? value;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppCountryPicker(
            countries: const ['France', 'Belgique', 'Canada'],
            value: value,
            onChanged: (v) => value = v,
          ),
        ),
      ),
    );

    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bel');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belgique'));
    await tester.pumpAndSettle();
    expect(value, 'Belgique');
  });
}
