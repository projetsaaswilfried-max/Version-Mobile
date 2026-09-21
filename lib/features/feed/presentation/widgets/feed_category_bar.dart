import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/mapping/feed_chip.dart';

class FeedCategoryBar extends StatelessWidget {
  const FeedCategoryBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FeedChip selected;
  final ValueChanged<FeedChip> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < FeedChip.allVisible.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Builder(
                builder: (context) {
                  final chip = FeedChip.allVisible[i];
                  return _Chip(
                    key: ValueKey('feed-chip-${chip.name}'),
                    label: chip.label,
                    selected: selected == chip,
                    onTap: () => onSelected(chip),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primary : colors.chipBackground,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text(
              label,
              style: typography.label.copyWith(
                color: selected ? colors.surface : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
