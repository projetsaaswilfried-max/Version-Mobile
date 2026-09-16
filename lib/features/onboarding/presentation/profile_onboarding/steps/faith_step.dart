import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../onboarding_draft.dart';
import '../onboarding_flow_controller.dart';

class FaithStep extends ConsumerWidget {
  const FaithStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);
    final draft = state.draft;
    final errors = state.fieldErrors;
    final colors = context.colors;
    final typography = context.typography;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        Text(
          'Ma foi',
          style: typography.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Confession et situation matrimoniale.',
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppTextField(
          label: 'Confession chrétienne',
          maxLines: 3,
          errorText: errors['faithConfession'],
          onChanged: (v) =>
              controller.updateDraft((d) => d.copyWith(faithConfession: v)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Situation matrimoniale', style: typography.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final s in OnboardingMaritalStatus.values)
              ChoiceChip(
                label: Text(_maritalLabel(s)),
                selected: draft.maritalStatus == s,
                onSelected: (_) => controller.updateDraft(
                  (d) => d.copyWith(maritalStatus: s),
                ),
              ),
          ],
        ),
        if (errors['maritalStatus'] != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              errors['maritalStatus']!,
              style: typography.bodySmall.copyWith(color: colors.error),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          label: 'Taille (cm, optionnel)',
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final n = int.tryParse(v.trim());
            controller.updateDraft(
              (d) => n == null
                  ? d.copyWith(clearHeight: true)
                  : d.copyWith(heightCm: n),
            );
          },
        ),
      ],
    );
  }

  String _maritalLabel(OnboardingMaritalStatus s) => switch (s) {
    OnboardingMaritalStatus.single => 'Célibataire',
    OnboardingMaritalStatus.divorced => 'Divorcé(e)',
    OnboardingMaritalStatus.widowed => 'Veuf / veuve',
  };
}
