import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/auth/di/auth_providers.dart';
import 'package:agapeo/features/auth/presentation/session_stub/session_stub_page.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/auth_test_fakes.dart';

void main() {
  testWidgets('stub opens onboarding flow', (tester) async {
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

    await tester.tap(find.text('Continuer l\'onboarding'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlowPage), findsOneWidget);
    expect(find.text('Informations essentielles'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('next shows validation when essentials empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingFlowPage(),
        ),
      ),
    );

    await tester.tap(find.text('Suivant'));
    await tester.pump();

    expect(find.text('Choisis ton genre.'), findsOneWidget);
    expect(find.text('Tes photos'), findsNothing);
  });
}
