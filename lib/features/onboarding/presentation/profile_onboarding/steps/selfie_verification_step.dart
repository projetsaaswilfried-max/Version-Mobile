import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../onboarding_flow_controller.dart';

/// Selfie de vérification - toujours collé à l'étape photo précédente
/// (demande du porteur) : impossible d'avancer sans, pas de "Passer".
class SelfieVerificationStep extends ConsumerWidget {
  const SelfieVerificationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(onboardingFlowProvider).draft;
    final controller = ref.read(onboardingFlowProvider.notifier);
    final selfie = draft.selfiePath;
    final colors = context.colors;
    final typography = context.typography;

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
          Text(
            'Ce selfie confirme que la photo de profil, c\'est bien toi. Il '
            'ne se prend qu\'en direct à la caméra, jamais depuis la '
            'galerie.',
            style: typography.bodyMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AspectRatio(
            aspectRatio: 1,
            child: selfie == null
                ? _EmptySelfieFrame(onTap: controller.pickSelfie)
                : _FilledSelfieFrame(
                    path: selfie,
                    onRetake: controller.pickSelfie,
                    onRemove: controller.clearSelfie,
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptySelfieFrame extends StatelessWidget {
  const _EmptySelfieFrame({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      color: colors.surface,
      borderRadius: AppRadius.lgRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: colors.border),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSpacing.xxxl + AppSpacing.sm,
                  height: AppSpacing.xxxl + AppSpacing.sm,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.face_retouching_natural_outlined,
                    size: AppSpacing.xl,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Prendre un selfie',
                  style: typography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Caméra frontale',
                  style: typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilledSelfieFrame extends StatelessWidget {
  const _FilledSelfieFrame({
    required this.path,
    required this.onRetake,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onRetake;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ClipRRect(
      borderRadius: AppRadius.lgRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(path), fit: BoxFit.cover),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _OverlayButton(
              tooltip: 'Supprimer',
              icon: Icons.close_rounded,
              onPressed: onRemove,
              background: colors.scrim.withValues(alpha: 0.55),
              foreground: colors.onScrim,
            ),
          ),
          Positioned(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Center(
              child: _OverlayButton(
                tooltip: 'Reprendre',
                icon: Icons.cameraswitch_outlined,
                label: 'Reprendre',
                onPressed: onRetake,
                background: colors.scrim.withValues(alpha: 0.55),
                foreground: colors.onScrim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.label,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: AppRadius.pillRadius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.pillRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: label == null ? AppSpacing.sm : AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: AppSpacing.lg + AppSpacing.xs,
                  color: foreground,
                ),
                if (label != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label!,
                    style: context.typography.label.copyWith(color: foreground),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
