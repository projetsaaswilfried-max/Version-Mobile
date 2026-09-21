import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Settings list row: icon tile, label, optional subtitle, chevron.
class AppSettingsRow extends StatelessWidget {
  const AppSettingsRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.danger = false,
    this.showChevron = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? subtitle;
  final bool danger;
  final bool showChevron;
  final bool compact;

  static const double _tileSize = AppSpacing.xxxl - AppSpacing.xs;
  static const double _compactTileSize = AppSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final labelColor = danger ? colors.error : colors.textPrimary;
    final iconColor = danger ? colors.error : colors.primary;

    final tileSize = compact ? _compactTileSize : _tileSize;

    return ListTile(
      onTap: onTap,
      dense: compact,
      minVerticalPadding: compact ? AppSpacing.sm : AppSpacing.md,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: icon == null
          ? null
          : SizedBox(
              width: tileSize,
              height: tileSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: AppSpacing.lg),
                ),
              ),
            ),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: typography.bodyLarge.copyWith(
          color: labelColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: typography.bodySmall.copyWith(color: colors.textSecondary),
            ),
      trailing: showChevron
          ? Icon(
              Icons.chevron_right,
              color: danger ? colors.error : colors.textSecondary,
            )
          : null,
    );
  }
}
