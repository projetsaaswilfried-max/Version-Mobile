import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../onboarding_draft.dart';
import '../onboarding_flow_controller.dart';

class PhotosStep extends ConsumerWidget {
  const PhotosStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingFlowProvider);
    final controller = ref.read(onboardingFlowProvider.notifier);
    final draft = state.draft;
    final colors = context.colors;
    final typography = context.typography;
    final canAdd = draft.photoPaths.length < OnboardingDraft.maxFreePhotos;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        Text(
          'Tes photos',
          style: typography.headline.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Au moins 1 photo. Jusqu\'à ${OnboardingDraft.maxFreePhotos} en gratuit.',
          style: typography.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (state.fieldErrors['photos'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              state.fieldErrors['photos']!,
              style: typography.bodySmall.copyWith(color: colors.error),
            ),
          ),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var i = 0; i < draft.photoPaths.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.file(
                      File(draft.photoPaths[i]),
                      width: 110,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surface.withValues(alpha: 0.9),
                      ),
                      onPressed: () => controller.removePhoto(i),
                      icon: Icon(Icons.close, color: colors.textPrimary, size: 18),
                    ),
                  ),
                ],
              ),
            if (canAdd)
              SizedBox(
                width: 110,
                height: 140,
                child: OutlinedButton(
                  onPressed: controller.addPhoto,
                  child: const Icon(Icons.add_a_photo_outlined),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Ajouter une photo',
          variant: AppButtonVariant.secondary,
          onPressed: canAdd ? controller.addPhoto : null,
        ),
      ],
    );
  }
}
