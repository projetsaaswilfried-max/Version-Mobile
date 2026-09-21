import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, text }

/// Design-system button: wraps [ElevatedButton]/[OutlinedButton]/[TextButton]
/// so every screen picks a variant instead of restyling by hand.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.expanded = true,
    this.compact = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool expanded;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final indicatorSize = compact
        ? AppSpacing.lg
        : AppSpacing.xl - AppSpacing.xs;
    final Widget child;
    if (isLoading) {
      child = SizedBox(
        width: indicatorSize,
        height: indicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: AppSpacing.xxs,
          color: variant == AppButtonVariant.primary
              ? context.colors.surface
              : context.colors.primary,
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSpacing.lg),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      child = Text(label);
    }

    final ButtonStyle? overlayStyle;
    if (compact) {
      overlayStyle = ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg + AppSpacing.xxs,
          ),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          context.typography.label.copyWith(color: context.colors.surface),
        ),
      );
    } else if (!expanded) {
      overlayStyle = const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, AppSpacing.buttonHeight)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    } else {
      overlayStyle = null;
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return _maybeExpand(
          ElevatedButton(onPressed: onTap, style: overlayStyle, child: child),
        );
      case AppButtonVariant.secondary:
        return _maybeExpand(
          OutlinedButton(onPressed: onTap, style: overlayStyle, child: child),
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: context.colors.primary),
          child: child,
        );
    }
  }

  Widget _maybeExpand(Widget button) {
    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
