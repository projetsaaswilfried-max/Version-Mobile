import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, text }

/// Design-system button — wraps [ElevatedButton]/[OutlinedButton]/[TextButton]
/// so every screen picks a variant instead of restyling by hand.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final onTap = isLoading ? null : onPressed;
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary ? Colors.white : context.colors.primary,
            ),
          )
        : Text(label);

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: onTap, child: child),
        );
      case AppButtonVariant.secondary:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.primary,
              side: BorderSide(color: context.colors.primary),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
              textStyle: context.typography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            child: child,
          ),
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: context.colors.primary),
          child: child,
        );
    }
  }
}
