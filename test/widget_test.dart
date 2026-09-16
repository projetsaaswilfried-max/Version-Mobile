import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/presentation/age_gate/age_gate_page.dart';
import 'package:agapeo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/auth_test_fakes.dart';

void main() {
  testWidgets('AgapeoApp shows the splash page', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ageGateStoreProvider.overrideWithValue(FakeAgeGateStore()),
        ],
        child: const AgapeoApp(),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AgapeoApp routes from splash to age gate', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          ageGateStoreProvider.overrideWithValue(FakeAgeGateStore()),
        ],
        child: const AgapeoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AgeGatePage), findsOneWidget);
  });
}
