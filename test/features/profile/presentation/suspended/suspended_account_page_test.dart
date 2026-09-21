import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
import 'package:agapeo/features/profile/presentation/suspended/suspended_account_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  testWidgets('shows suspended title and logout returns to welcome', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SuspendedAccountPage(),
        ),
      ),
    );

    expect(find.text('Compte suspendu'), findsOneWidget);
    expect(find.text('Déconnexion'), findsOneWidget);

    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();
    expect(find.text('Se déconnecter ?'), findsOneWidget);

    await tester.tap(find.text('Déconnexion').last);
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets('cancel logout keeps suspended page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SuspendedAccountPage(),
        ),
      ),
    );

    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.byType(SuspendedAccountPage), findsOneWidget);
    expect(find.byType(WelcomePage), findsNothing);
  });
}
