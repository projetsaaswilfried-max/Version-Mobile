import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/config/countries.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../onboarding_flow_controller.dart';
import '../onboarding_option_mapping.dart';

class EssentialsStep extends ConsumerWidget {
  const EssentialsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);
    final draft = state.draft;
    final errors = state.fieldErrors;
    final typography = context.typography;
    final colors = context.colors;
    final locked = state.essentialsLocked;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (locked) ...[
            Text(
              'Ces infos sont déjà enregistrées et ne peuvent plus être modifiées.',
              style: typography.bodySmall.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Genre', style: typography.label),
          const SizedBox(height: AppSpacing.sm),
          IgnorePointer(
            ignoring: locked,
            child: Opacity(
              opacity: locked ? 0.7 : 1,
              child: AppGenderCards(
                items: onboardingGenderItems(),
                selectedId: draft.gender == null
                    ? null
                    : onboardingGenderId(draft.gender!),
                errorText: errors['gender'],
                onSelected: (id) {
                  final gender = onboardingGenderFromId(id);
                  if (gender == null) return;
                  controller.updateDraft((d) => d.copyWith(gender: gender));
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          IgnorePointer(
            ignoring: locked,
            child: Opacity(
              opacity: locked ? 0.7 : 1,
              child: AppBirthDateField(
                value: draft.birthDate,
                errorText: errors['birthDate'],
                onChanged: (d) => controller.updateDraft(
                  (draft) => draft.copyWith(birthDate: d),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          IgnorePointer(
            ignoring: locked,
            child: Opacity(
              opacity: locked ? 0.7 : 1,
              child: AppCountryPicker(
                countries: kOnboardingCountries,
                value: draft.country,
                errorText: errors['country'],
                onChanged: (c) =>
                    controller.updateDraft((d) => d.copyWith(country: c)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
