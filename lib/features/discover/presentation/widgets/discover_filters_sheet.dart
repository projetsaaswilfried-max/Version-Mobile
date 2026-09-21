import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/discover_query.dart';

class DiscoverFiltersSheet extends StatefulWidget {
  const DiscoverFiltersSheet({
    super.key,
    this.initialQuery = const DiscoverQuery(),
    required this.onApply,
    required this.onReset,
    this.onDismiss,
  });

  final DiscoverQuery initialQuery;
  final ValueChanged<DiscoverQuery> onApply;
  final VoidCallback onReset;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context, {
    DiscoverQuery initialQuery = const DiscoverQuery(),
    required ValueChanged<DiscoverQuery> onApply,
    required VoidCallback onReset,
  }) {
    final colors = context.colors;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      barrierColor: colors.textPrimary.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return DiscoverFiltersSheet(
          initialQuery: initialQuery,
          onApply: (query) {
            onApply(query);
            Navigator.of(ctx).pop();
          },
          onReset: () {
            onReset();
            Navigator.of(ctx).pop();
          },
          onDismiss: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }

  @override
  State<DiscoverFiltersSheet> createState() => _DiscoverFiltersSheetState();
}

class _DiscoverFiltersSheetState extends State<DiscoverFiltersSheet> {
  late final TextEditingController _city;
  late final TextEditingController _denomination;
  late final TextEditingController _profession;

  @override
  void initState() {
    super.initState();
    _city = TextEditingController(text: widget.initialQuery.city ?? '');
    _denomination = TextEditingController(
      text: widget.initialQuery.denomination ?? '',
    );
    _profession = TextEditingController(
      text: widget.initialQuery.profession ?? '',
    );
  }

  @override
  void dispose() {
    _city.dispose();
    _denomination.dispose();
    _profession.dispose();
    super.dispose();
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _apply() {
    widget.onApply(
      DiscoverQuery(
        city: _trimOrNull(_city.text),
        denomination: _trimOrNull(_denomination.text),
        profession: _trimOrNull(_profession.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          (bottom > 0 ? bottom : AppSpacing.lg) + keyboard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filtres', style: typography.headline),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              key: const ValueKey('discover-filter-city'),
              controller: _city,
              label: 'Ville',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('discover-filter-denomination'),
              controller: _denomination,
              label: 'Dénomination',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              key: const ValueKey('discover-filter-profession'),
              controller: _profession,
              label: 'Profession',
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Appliquer', onPressed: _apply),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Réinitialiser',
              variant: AppButtonVariant.secondary,
              onPressed: widget.onReset,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Fermer',
              variant: AppButtonVariant.text,
              onPressed: widget.onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
