import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agapeo/main.dart';

void main() {
  testWidgets('AgapeoApp shows the splash page', (WidgetTester tester) async {
    await tester.pumpWidget(const AgapeoApp());

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
