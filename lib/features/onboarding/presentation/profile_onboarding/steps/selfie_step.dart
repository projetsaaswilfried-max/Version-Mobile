import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../onboarding_flow_controller.dart';

class SelfieStep extends ConsumerWidget {
  const SelfieStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);
    final draft = state.draft;
    final colors = context.colors;
    final typography = context.typography;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        Text(
          'Selfie de vérification',
          style: typography.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Capture caméra uniquement (pas d\'import fichier).',
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (state.fieldErrors['selfie'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              state.fieldErrors['selfie']!,
              style: typography.bodySmall.copyWith(color: colors.error),
            ),
          ),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: draft.selfiePath == null
                ? Container(
                    width: 220,
                    height: 280,
                    color: colors.border.withValues(alpha: 0.3),
                    child: Icon(
                      Icons.photo_camera_front_outlined,
                      size: 64,
                      color: colors.textSecondary,
                    ),
                  )
                : Image.file(
                    File(draft.selfiePath!),
                    width: 220,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: draft.selfiePath == null
              ? 'Ouvrir la caméra'
              : 'Reprendre le selfie',
          onPressed: controller.captureSelfie,
        ),
        if (draft.selfiePath != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Supprimer',
            variant: AppButtonVariant.secondary,
            onPressed: controller.clearSelfie,
          ),
        ],
      ],
    );
  }
}
