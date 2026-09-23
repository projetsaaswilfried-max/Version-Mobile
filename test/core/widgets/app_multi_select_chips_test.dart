import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_multi_select_chips.dart';
import 'package:agapeo/core/widgets/app_option_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const items = [
    AppOptionItem(id: 'Randonnée', label: 'Randonnée'),
    AppOptionItem(id: 'Cuisine', label: 'Cuisine'),
    AppOptionItem(id: 'Lecture', label: 'Lecture'),
  ];

  Future<void> pump(
    WidgetTester tester, {
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
    int max = 2,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppMultiSelectChips(
            label: 'Centres d\'intérêt',
            hint: 'choisis-en au moins un',
            items: items,
            selected: selected,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('tapping an option selects it', (tester) async {
    List<String>? result;
    await pump(tester, selected: const [], onChanged: (v) => result = v);

    await tester.tap(find.text('Randonnée'));
    await tester.pump();

    expect(result, ['Randonnée']);
  });

  testWidgets('tapping a selected option deselects it', (tester) async {
    List<String>? result;
    await pump(
      tester,
      selected: const ['Randonnée'],
      onChanged: (v) => result = v,
    );

    await tester.tap(find.text('Randonnée'));
    await tester.pump();

    expect(result, isEmpty);
  });

  testWidgets('ignores taps past the max', (tester) async {
    var callCount = 0;
    await pump(
      tester,
      selected: const ['Randonnée', 'Cuisine'],
      onChanged: (_) => callCount++,
      max: 2,
    );

    await tester.tap(find.text('Lecture'));
    await tester.pump();

    expect(callCount, 0);
  });

  testWidgets('shows the errorText when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppMultiSelectChips(
            label: 'Centres d\'intérêt',
            hint: 'choisis-en au moins un',
            items: items,
            selected: const [],
            max: 2,
            onChanged: (_) {},
            errorText: 'Ajoute au moins un centre d\'intérêt.',
          ),
        ),
      ),
    );

    expect(find.text('Ajoute au moins un centre d\'intérêt.'), findsOneWidget);
  });
}
