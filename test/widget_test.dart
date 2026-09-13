import 'package:flutter_test/flutter_test.dart';

import 'package:agapeo/main.dart';

void main() {
  testWidgets('AgapeoApp shows the splash page', (WidgetTester tester) async {
    await tester.pumpWidget(const AgapeoApp());

    expect(find.text('Agapeo'), findsOneWidget);
  });
}
