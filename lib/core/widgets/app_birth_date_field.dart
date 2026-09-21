import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class AppBirthDateField extends StatelessWidget {
  const AppBirthDateField({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'Date de naissance',
    this.errorText,
    this.now,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String label;
  final String? errorText;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final display = value == null
        ? 'Choisir'
        : MaterialLocalizations.of(context).formatMediumDate(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.label),
        const SizedBox(height: AppSpacing.xs),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      display,
                      style: typography.bodyLarge.copyWith(
                        color: value == null
                            ? colors.textSecondary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, color: colors.primary),
                ],
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
    final clock = now ?? DateTime.now();
    var draft = value ?? DateTime(clock.year - 25, clock.month, clock.day);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return Localizations.override(
          context: ctx,
          locale: const Locale('fr'),
          child: Builder(
            builder: (localizedCtx) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Date de naissance',
                        style: localizedCtx.typography.headline,
                      ),
                      SizedBox(
                        height: 200,
                        child: CupertinoTheme(
                          data: CupertinoThemeData(
                            primaryColor: localizedCtx.colors.primary,
                            textTheme: CupertinoTextThemeData(
                              dateTimePickerTextStyle:
                                  localizedCtx.typography.bodyLarge,
                            ),
                          ),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: draft,
                            maximumDate: clock,
                            minimumDate: DateTime(clock.year - 100),
                            onDateTimeChanged: (d) => draft = d,
                          ),
                        ),
                      ),
                      AppButton(
                        label: 'Valider',
                        onPressed: () {
                          onChanged(draft);
                          Navigator.of(localizedCtx).pop();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
