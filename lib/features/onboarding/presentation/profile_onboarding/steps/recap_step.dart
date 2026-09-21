import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../onboarding_flow_controller.dart';
import '../onboarding_option_mapping.dart';

class RecapStep extends ConsumerWidget {
  const RecapStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingFlowProvider).draft;
    final controller = ref.read(onboardingFlowProvider.notifier);
    final photo = draft.profilePhotoPath;
    final typography = context.typography;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: AppSpacing.xxl * 2,
              height: AppSpacing.xxl * 2,
              child: photo == null
                  ? const AppAvatarPlaceholder(
                      circle: true,
                      iconSize: AppSpacing.xl,
                    )
                  : CircleAvatar(
                      radius: AppSpacing.xxl,
                      backgroundImage: FileImage(File(photo)),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Vérifie tes infos',
            style: typography.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSettingsGroup(
            padding: EdgeInsets.zero,
            children: [
              AppSettingsRow(
                label: 'Genre',
                subtitle: draft.gender == null
                    ? 'Non renseigné'
                    : onboardingGenderLabel(draft.gender!),
                icon: Icons.wc_outlined,
                onTap: () => controller.goToStep(0),
              ),
              AppSettingsRow(
                label: 'Âge',
                subtitle: _ageLabel(draft.birthDate),
                icon: Icons.cake_outlined,
                onTap: () => controller.goToStep(0),
              ),
              AppSettingsRow(
                label: 'Pays',
                subtitle: draft.country?.trim().isNotEmpty == true
                    ? draft.country
                    : 'Non renseigné',
                icon: Icons.public_outlined,
                onTap: () => controller.goToStep(0),
              ),
              AppSettingsRow(
                label: 'Confession',
                subtitle: draft.faithConfession.trim().isEmpty
                    ? 'Non renseigné'
                    : draft.faithConfession.trim(),
                icon: Icons.menu_book_outlined,
                onTap: () => controller.goToStep(1),
              ),
              AppSettingsRow(
                label: 'Situation',
                subtitle: draft.maritalStatus == null
                    ? 'Non renseigné'
                    : onboardingMaritalLabel(draft.maritalStatus!),
                icon: Icons.favorite_outline,
                onTap: () => controller.goToStep(1),
              ),
              AppSettingsRow(
                label: 'Pourquoi le mariage',
                subtitle: draft.whyMarriage.trim().isEmpty
                    ? 'Non renseigné'
                    : draft.whyMarriage.trim(),
                icon: Icons.favorite_border,
                onTap: () => controller.goToStep(1),
              ),
              AppSettingsRow(
                label: 'Photo',
                subtitle: photo == null ? 'Aucune' : 'Ajoutée',
                icon: Icons.photo_outlined,
                onTap: () => controller.goToStep(2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _ageLabel(DateTime? birthDate) {
    if (birthDate == null) return 'Non renseigné';
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hadBirthday =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) age -= 1;
    return '$age ans';
  }
}
