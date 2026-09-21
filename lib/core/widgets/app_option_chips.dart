import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_option_item.dart';

export 'app_option_item.dart';

/// Single-select Datify interest chips (filled wash pills).
class AppOptionChips extends StatelessWidget {
  const AppOptionChips({
    super.key,
    required this.items,
    required this.onSelected,
    this.selectedId,
    this.errorText,
  });

  final List<AppOptionItem> items;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in items)
              Semantics(
                button: true,
                selected: selectedId == item.id,
                child: Material(
                  color: selectedId == item.id
                      ? colors.primary
                      : colors.primary.withValues(alpha: 0.1),
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => onSelected(item.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.icon != null) ...[
                            Icon(
                              item.icon,
                              size: AppSpacing.xl - AppSpacing.xs,
                              color: selectedId == item.id
                                  ? colors.surface
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            item.label,
                            style: typography.bodyLarge.copyWith(
                              color: selectedId == item.id
                                  ? colors.surface
                                  : colors.textPrimary,
                              fontWeight: selectedId == item.id
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            style: typography.bodySmall.copyWith(color: colors.error),
          ),
        ],
      ],
    );
  }
}
