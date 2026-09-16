import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/presentation/session_stub/session_stub_page.dart';
import 'package:agapeo/features/auth/presentation/welcome/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  testWidgets('shows email and logout returns to welcome', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SessionStubPage(email: 'a@b.co'),
        ),
      ),
    );

    expect(find.text('Session'), findsOneWidget);
    expect(find.text('a@b.co'), findsOneWidget);
    expect(find.text('Continuer l\'onboarding'), findsOneWidget);
    expect(find.text('Déconnexion'), findsOneWidget);

    await tester.tap(find.text('Déconnexion'));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomePage), findsOneWidget);
  });
}
