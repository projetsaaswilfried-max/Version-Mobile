import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_search_field.dart';

class AppCountryPicker extends StatelessWidget {
  const AppCountryPicker({
    super.key,
    required this.countries,
    required this.onChanged,
    this.value,
    this.label = 'Pays',
    this.hint = 'Choisir',
    this.errorText,
    this.filled = false,
    this.onCleared,
  });

  final List<String> countries;
  final String? value;
  final ValueChanged<String> onChanged;
  final String label;
  final String hint;
  final String? errorText;
  final bool filled;
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final hasValue = value != null && value!.trim().isNotEmpty;
    final radius = filled ? AppRadius.lgRadius : AppRadius.mdRadius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.label),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: filled ? colors.chipBackground : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: filled
                ? BorderSide.none
                : BorderSide(
                    color: errorText != null ? colors.error : colors.border,
                  ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: () => _openSheet(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.inputHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasValue ? value! : hint,
                        style: typography.bodyLarge.copyWith(
                          color: hasValue
                              ? colors.textPrimary
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                    if (hasValue && onCleared != null)
                      IconButton(
                        tooltip: 'Effacer',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: AppSpacing.xxl,
                          minHeight: AppSpacing.xxl,
                        ),
                        onPressed: onCleared,
                        icon: Icon(
                          Icons.close,
                          size: AppSpacing.lg,
                          color: colors.textSecondary,
                        ),
                      )
                    else
                      Icon(Icons.expand_more, color: colors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
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

  Future<void> _openSheet(BuildContext context) async {
    var query = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final filtered = countries
                .where((c) => c.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: AppSearchField(
                        onChanged: (v) => setState(() => query = v),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          return ListTile(
                            title: Text(c),
                            trailing: value == c
                                ? Icon(Icons.check, color: ctx.colors.primary)
                                : null,
                            onTap: () {
                              onChanged(c);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
