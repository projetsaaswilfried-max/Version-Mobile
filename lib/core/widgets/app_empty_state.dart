import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Empty state: clay illustration (or soft brand disc + icon), title, optional
/// detail and CTA. Use [compact] for inline contexts (comments, nested lists).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.detail,
    this.illustrationAsset,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.actionVariant = AppButtonVariant.secondary,
    this.compact = false,
  });

  final String title;
  final String? detail;
  final String? illustrationAsset;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppButtonVariant actionVariant;
  final bool compact;

  static const double _discSize = AppSpacing.xxxl + AppSpacing.xl;
  static const double _discSizeCompact = AppSpacing.xxxl + AppSpacing.sm;
  static const double _illustrationSize = AppSpacing.xxxl * 3 + AppSpacing.xl;
  static const double _illustrationSizeCompact = AppSpacing.xxxl * 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final pad = compact ? AppSpacing.lg : AppSpacing.xl;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: _visual(context)),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: compact ? typography.bodyLarge : typography.title,
              ),
              if (detail != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                AppButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: actionVariant,
                  compact: true,
                  expanded: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _visual(BuildContext context) {
    final colors = context.colors;
    final asset = illustrationAsset;
    if (asset != null) {
      final size = compact ? _illustrationSizeCompact : _illustrationSize;
      final dpr = MediaQuery.devicePixelRatioOf(context);
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: (size * dpr).round(),
        filterQuality: FilterQuality.medium,
      );
    }

    final disc = compact ? _discSizeCompact : _discSize;
    return SizedBox(
      width: disc,
      height: disc,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryLight.withValues(alpha: 0.35),
              colors.primary.withValues(alpha: 0.18),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            size: compact ? AppSpacing.xl : AppSpacing.xxl,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}
