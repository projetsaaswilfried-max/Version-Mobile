import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

class DiscoverCenteredMessage extends StatelessWidget {
  const DiscoverCenteredMessage({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.emphasizeTitle = false,
    this.muted = false,
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool emphasizeTitle;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: emphasizeTitle
                  ? context.typography.headline
                  : context.typography.bodyLarge.copyWith(
                      color: muted ? context.colors.textSecondary : null,
                    ),
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: context.typography.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
