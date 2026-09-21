import 'package:agapeo/core/config/app_assets.dart';
import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/widgets/onboarding_step_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: OnboardingStepHero(
            asset: AppAssets.onboardingHeroEssentials,
            title: 'Parle-nous de toi',
            subtitle: 'Quelques infos pour commencer',
          ),
        ),
      ),
    );

    expect(find.text('Parle-nous de toi'), findsOneWidget);
  });
}
