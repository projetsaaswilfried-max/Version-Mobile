import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../onboarding_flow_controller.dart';

class PreferencesStep extends ConsumerWidget {
  const PreferencesStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);
    final errors = state.fieldErrors;
    final colors = context.colors;
    final typography = context.typography;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        Text(
          'Ce que je recherche',
          style: typography.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Tu pourras enrichir ton profil plus tard.',
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppTextField(
          label: 'Pourquoi cherches-tu le mariage ?',
          maxLines: 4,
          errorText: errors['whyMarriage'],
          onChanged: (v) =>
              controller.updateDraft((d) => d.copyWith(whyMarriage: v)),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: 'Présentation courte (optionnel)',
          maxLines: 3,
          onChanged: (v) => controller.updateDraft((d) => d.copyWith(bio: v)),
        ),
        const SizedBox(height: AppSpacing.xxl),
        TextButton(
          onPressed: () {
            controller.finishWithoutSubmit();
          },
          child: Text(
            'Terminer sans soumettre',
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}
