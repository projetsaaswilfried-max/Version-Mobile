import 'package:agapeo/core/theme/app_theme.dart';
import 'package:agapeo/core/widgets/app_option_chips.dart';
import 'package:agapeo/core/widgets/app_select_field.dart';
import 'package:agapeo/core/widgets/app_text_field.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_draft.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_controller.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/onboarding_flow_state.dart';
import 'package:agapeo/features/onboarding/presentation/profile_onboarding/steps/faith_why_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('faith why step hydrates confession from draft', (tester) async {
    const confession = 'Évangélique';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingFlowProvider.overrideWith(
            () => _OnboardingFlowWithDraft(
              const OnboardingDraft(faithConfession: confession),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: FaithWhyStep()),
        ),
      ),
    );

    expect(find.text(confession), findsOneWidget);
  });

  testWidgets('faith why step shows select, marital chips and why field', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: FaithWhyStep()),
        ),
      ),
    );

    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byType(AppSelectField), findsOneWidget);
    expect(find.byType(AppOptionChips), findsOneWidget);
    expect(find.text('Célibataire sans enfant'), findsOneWidget);
    expect(find.text('Célibataire avec enfant(s)'), findsOneWidget);
    expect(find.byType(AppTextField), findsOneWidget);
    expect(find.text('Confession chrétienne'), findsOneWidget);
    expect(find.text('Pourquoi cherches-tu le mariage ?'), findsOneWidget);
  });
}

class _OnboardingFlowWithDraft extends OnboardingFlowController {
  _OnboardingFlowWithDraft(this.initialDraft);

  final OnboardingDraft initialDraft;

  @override
  OnboardingFlowState build() => OnboardingFlowState(draft: initialDraft);
}
