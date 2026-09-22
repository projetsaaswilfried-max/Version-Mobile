import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';

enum ThreadOptionsAction { report, block }

/// Options du fil (Signaler / Bloquer) - même chrome que
/// [ProfileSafetySheet], pas un `PopupMenuButton` (hors design system).
class ThreadOptionsSheet extends StatelessWidget {
  const ThreadOptionsSheet({super.key});

  static Future<ThreadOptionsAction?> show(BuildContext context) {
    final colors = context.colors;
    return showModalBottomSheet<ThreadOptionsAction>(
      context: context,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => const ThreadOptionsSheet(),
    );
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
            const SizedBox(height: AppSpacing.md),
            _ThreadOptionTile(
              icon: Icons.flag_outlined,
              label: 'Signaler',
              onTap: () => Navigator.pop(context, ThreadOptionsAction.report),
            ),
            _ThreadOptionTile(
              icon: Icons.block,
              label: 'Bloquer',
              destructive: true,
              onTap: () => Navigator.pop(context, ThreadOptionsAction.block),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadOptionTile extends StatelessWidget {
  const _ThreadOptionTile({
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
              Icon(Icons.chevron_right, color: colors.muted, size: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
