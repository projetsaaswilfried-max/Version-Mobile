import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_option_item.dart';

/// Multi-select filter chips: filled primary when selected, outlined otherwise.
class AppFilterChips extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onToggled,
  });

  final List<AppOptionItem> items;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final item in items)
          Semantics(
            button: true,
            selected: selectedIds.contains(item.id),
            child: Material(
              color: selectedIds.contains(item.id)
                  ? colors.primary
                  : colors.surface,
              shape: StadiumBorder(
                side: selectedIds.contains(item.id)
                    ? BorderSide.none
                    : BorderSide(color: colors.border),
              ),
              child: InkWell(
                key: ValueKey('filter-chip-${item.id}'),
                customBorder: const StadiumBorder(),
                onTap: () => onToggled(item.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md + AppSpacing.xs,
                    vertical: AppSpacing.sm + AppSpacing.xs,
                  ),
                  child: Text(
                    item.label,
                    style: typography.bodyMedium.copyWith(
                      color: selectedIds.contains(item.id)
                          ? colors.surface
                          : colors.textPrimary,
                      fontWeight: selectedIds.contains(item.id)
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
