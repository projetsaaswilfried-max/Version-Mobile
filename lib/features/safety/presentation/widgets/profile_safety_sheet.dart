import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/report_reason.dart';
import 'report_sheet.dart';

/// Choix Signaler / Bloquer - fond blanc, même chrome que [ReportSheet].
class ProfileSafetySheet extends StatelessWidget {
  const ProfileSafetySheet({super.key});

  /// Retourne `'report'`, `'block'`, ou `null` si fermé.
  static Future<String?> show(BuildContext context) {
    final colors = context.colors;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => const ProfileSafetySheet(),
    );
  }

  /// Enchaîne le sheet d'actions puis [ReportSheet] / [confirmAndBlock].
  /// Retourne `true` si un blocage a réussi (pour refresh / fermer la fiche).
  static Future<bool> present({
    required BuildContext context,
    required WidgetRef ref,
    required String profileId,
  }) async {
    final action = await show(context);
    if (!context.mounted || action == null) return false;

    if (action == 'report') {
      final sent = await ReportSheet.show(
        context,
        targetType: ReportTargetType.profile,
        targetId: profileId,
      );
      if (sent && context.mounted) {
        AppToast.show(context, 'Signalement envoyé.', isError: false);
      }
      return false;
    }

    if (action == 'block') {
      return confirmAndBlock(
        context: context,
        ref: ref,
        profileId: profileId,
      );
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSpacing.md,
                height: AppSpacing.xs,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Options', style: typography.headline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Signaler un comportement ou bloquer ce profil.',
              style: typography.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _SafetyActionTile(
              icon: Icons.flag_outlined,
              label: 'Signaler',
              onTap: () => Navigator.pop(context, 'report'),
            ),
            _SafetyActionTile(
              icon: Icons.block,
              label: 'Bloquer',
              destructive: true,
              onTap: () => Navigator.pop(context, 'block'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyActionTile extends StatelessWidget {
  const _SafetyActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final tint = destructive ? colors.error : colors.textPrimary;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: tint, size: AppSpacing.xl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: typography.bodyLarge.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.muted,
                size: AppSpacing.xl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
