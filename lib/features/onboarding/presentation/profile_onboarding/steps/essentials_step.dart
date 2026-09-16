import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../onboarding_draft.dart';
import '../onboarding_flow_controller.dart';

const kOnboardingCountries = <String>[
  'Côte d\'Ivoire',
  'Sénégal',
  'Cameroun',
  'France',
  'Belgique',
  'Canada',
  'Autre',
];

class EssentialsStep extends ConsumerWidget {
  const EssentialsStep({super.key});

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
          'Informations essentielles',
          style: typography.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Genre, âge et pays : verrouillés après validation.',
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('Genre', style: typography.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final g in OnboardingGender.values)
              ChoiceChip(
                label: Text(_genderLabel(g)),
                selected: draft.gender == g,
                onSelected: (_) =>
                    controller.updateDraft((d) => d.copyWith(gender: g)),
              ),
          ],
        ),
        if (errors['gender'] != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              errors['gender']!,
              style: typography.bodySmall.copyWith(color: colors.error),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Date de naissance', style: typography.bodyMedium),
          subtitle: Text(
            draft.birthDate == null
                ? 'Choisir'
                : MaterialLocalizations.of(context).formatMediumDate(
                    draft.birthDate!,
                  ),
            style: typography.bodyLarge,
          ),
          trailing: Icon(Icons.calendar_today_outlined, color: colors.primary),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: draft.birthDate ?? DateTime(now.year - 25),
              firstDate: DateTime(now.year - 100),
              lastDate: now,
            );
            if (picked != null) {
              controller.updateDraft((d) => d.copyWith(birthDate: picked));
            }
          },
        ),
        if (errors['birthDate'] != null)
          Text(
            errors['birthDate']!,
            style: typography.bodySmall.copyWith(color: colors.error),
          ),
        const SizedBox(height: AppSpacing.xl),
        Text('Pays', style: typography.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use - value still OK until Flutter 3.33
          value: draft.country,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: [
            for (final c in kOnboardingCountries)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) {
            if (v != null) {
              controller.updateDraft((d) => d.copyWith(country: v));
            }
          },
        ),
        if (errors['country'] != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              errors['country']!,
              style: typography.bodySmall.copyWith(color: colors.error),
            ),
          ),
      ],
    );
  }

  String _genderLabel(OnboardingGender g) => switch (g) {
    OnboardingGender.woman => 'Femme',
    OnboardingGender.man => 'Homme',
    OnboardingGender.other => 'Autre',
  };
}
