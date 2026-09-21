import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_photo_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty slot shows add affordance and calls onAdd', (tester) async {
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppPhotoGrid(
            paths: const [],
            maxSlots: 2,
            onAdd: () => added = true,
            onRemoveAt: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(added, isTrue);
  });
}
