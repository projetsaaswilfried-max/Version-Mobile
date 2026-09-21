import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/profile/di/profile_providers.dart';
import 'package:agapeo/features/profile/presentation/faith/faith_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/profile_account_test_fakes.dart';

void main() {
  testWidgets('shows faith fields and save', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileAccountRepositoryProvider.overrideWithValue(
            FakeProfileAccountRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const FaithPage()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Confession'), findsOneWidget);
    expect(find.text('Pourquoi le mariage'), findsOneWidget);
    expect(find.text('Verset préféré'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
  });
}
