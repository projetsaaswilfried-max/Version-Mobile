import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_option_item.dart';

/// Full-width selectable rows — outlined surface, primary accent when selected.
class AppOptionRows extends StatelessWidget {
  const AppOptionRows({
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
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _Row(
            item: items[i],
            selected: selectedId == items[i].id,
            onTap: () => onSelected(items[i].id),
          ),
        ],
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

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.selected, required this.onTap});

  final AppOptionItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.08)
          : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdRadius,
        side: BorderSide(
          color: selected ? colors.primary : colors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.inputHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: typography.bodyLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? colors.primary : colors.textSecondary,
                  size: AppSpacing.xl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
