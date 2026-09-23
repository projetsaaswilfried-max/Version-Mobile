import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';

/// Carte "complète ton profil" - message clair + CTA (D14 / D18).
///
/// Un pourcentage de complétion affiché ici donnait l'impression que le
/// profil progressait vers un objectif abstrait ; le porteur veut un
/// message concret sur la conséquence réelle (visible ou non dans
/// Découvrir), pas un chiffre.
class ProfileCompletionBanner extends StatelessWidget {
  const ProfileCompletionBanner({
    super.key,
    required this.onTap,
    this.onDismiss,
    this.icon = Icons.info_outline,
    this.title = 'Complète ton profil',
    this.subtitle =
        'Tant qu\'il n\'est pas complet, ton profil n\'apparaît pas dans '
            'Découvrir - il faudra ensuite valider ta photo pour être '
            'visible.',
  });

  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Material(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgRadius,
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AppSpacing.xxxl,
                    height: AppSpacing.xxxl,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: colors.primary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: typography.title.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle,
                          style: typography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: onDismiss,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.close,
                        size: AppSpacing.lg,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
