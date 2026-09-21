import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Closed-list select trigger + bottom sheet (never a native dropdown).
class AppSelectField extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.label,
    this.hint = 'Choisir',
    this.errorText,
    this.sheetTitle,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? label;
  final String hint;
  final String? errorText;
  final String? sheetTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final hasValue = value != null && value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: typography.label),
          const SizedBox(height: AppSpacing.xs),
        ],
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdRadius,
            side: BorderSide(
              color: errorText != null ? colors.error : colors.border,
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.mdRadius,
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        final colors = ctx.colors;
        final typography = ctx.typography;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: AppSpacing.xl,
                    height: AppSpacing.xs,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  sheetTitle ?? label ?? hint,
                  style: typography.title,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.sizeOf(ctx).height *
                        AppSpacing.sheetMaxHeightFactor *
                        0.65,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: colors.border,
                    ),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final selected = option == value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          option,
                          style: typography.bodyLarge.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected
                                ? colors.primary
                                : colors.textPrimary,
                          ),
                        ),
                        trailing: selected
                            ? Icon(Icons.check_circle, color: colors.primary)
                            : null,
                        onTap: () {
                          onChanged(option);
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
  }
}
