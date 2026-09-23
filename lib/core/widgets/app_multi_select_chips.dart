import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_filter_chips.dart';
import 'app_option_item.dart';

/// Sélection multiple à partir d'une liste fermée (ex. table de référence
/// Supabase) : chips à cocher, plafonnées à [max], plus de saisie libre.
class AppMultiSelectChips extends StatelessWidget {
  const AppMultiSelectChips({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selected,
    required this.max,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final String hint;
  final List<AppOptionItem> items;
  final List<String> selected;
  final int max;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;

  void _toggle(String id) {
    if (selected.contains(id)) {
      onChanged(selected.where((item) => item != id).toList());
      return;
    }
    if (selected.length >= max) return;
    onChanged([...selected, id]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.typography.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${selected.length}/$max · $hint',
          style: context.typography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFilterChips(
          items: items,
          selectedIds: selected.toSet(),
          onToggled: _toggle,
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            errorText!,
            style: context.typography.bodySmall.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
      ],
    );
  }
}
