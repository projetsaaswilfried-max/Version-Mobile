import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_option_item.dart';
import 'package:agapeo/core/widgets/app_option_rows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('option row shows check when selected', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppOptionRows(
            items: const [
              AppOptionItem(id: 'a', label: 'Célibataire sans enfant'),
              AppOptionItem(id: 'b', label: 'Divorcé(e)'),
            ],
            selectedId: 'a',
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Célibataire sans enfant'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });
}
