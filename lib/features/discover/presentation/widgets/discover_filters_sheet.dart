import 'package:flutter/material.dart';

import '../../../../core/config/church_denominations.dart';
import '../../../../core/config/countries.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../profile/domain/mapping/marital_status_label.dart';
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
  static const _maritalDbValues = [
    'SINGLE_NO_CHILDREN',
    'SINGLE_WITH_CHILDREN',
    'DIVORCED',
    'WIDOWED',
  ];

  late final TextEditingController _cityController;
  late final TextEditingController _professionController;
  late RangeValues _age;
  String? _country;
  late Set<String> _maritalStatuses;
  late Set<String> _denominations;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery.normalized;
    _cityController = TextEditingController(text: initial.city ?? '');
    _professionController = TextEditingController(
      text: initial.profession ?? '',
    );
    _age = RangeValues(
      (initial.ageMin ?? DiscoverQuery.minAge).toDouble(),
      (initial.ageMax ?? DiscoverQuery.maxAge).toDouble(),
    );
    _country = initial.country;
    _maritalStatuses = {...initial.maritalStatuses};
    _denominations = {...initial.denominations};
  }

  @override
  void dispose() {
    _cityController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  void _apply() {
    widget.onApply(
      DiscoverQuery(
        country: _country,
        city: _cityController.text,
        profession: _professionController.text,
        denominations: _denominations.toList(),
        maritalStatuses: _maritalStatuses.toList(),
        ageMin: _age.start.round(),
        ageMax: _age.end.round(),
      ).normalized,
    );
  }

  void _toggle(Set<String> target, String id) {
    setState(() {
      if (target.contains(id)) {
        target.remove(id);
      } else {
        target.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final height =
        MediaQuery.sizeOf(context).height * AppSpacing.sheetMaxHeightFactor;
    final ageMin = _age.start.round();
    final ageMax = _age.end.round();
    final maritalItems = [
      for (final db in _maritalDbValues)
        AppOptionItem(id: db, label: maritalStatusLabel(db) ?? db),
    ];
    final denominationItems = [
      for (final name in churchDenominations)
        AppOptionItem(id: name, label: name),
    ];

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close),
                  ),
                  Expanded(
                    child: Text(
                      'Filtres',
                      textAlign: TextAlign.center,
                      style: typography.title.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxxl),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RangeHeader(
                      label: 'Âge',
                      value: '$ageMin - $ageMax',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: colors.primary,
                        inactiveTrackColor: colors.chipBackground,
                        thumbColor: colors.primary,
                        overlayColor: colors.primary.withValues(alpha: 0.16),
                      ),
                      child: RangeSlider(
                        key: const ValueKey('discover-filter-age'),
                        values: _age,
                        min: DiscoverQuery.minAge.toDouble(),
                        max: DiscoverQuery.maxAge.toDouble(),
                        divisions: DiscoverQuery.maxAge - DiscoverQuery.minAge,
                        onChanged: (values) => setState(() => _age = values),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppCountryPicker(
                      key: const ValueKey('discover-filter-country'),
                      countries: kOnboardingCountries,
                      value: _country,
                      hint: 'Tous les pays',
                      onChanged: (country) => setState(() => _country = country),
                      onCleared: _country == null
                          ? null
                          : () => setState(() => _country = null),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      key: const ValueKey('discover-filter-city'),
                      label: 'Ville',
                      hint: 'Toutes les villes',
                      controller: _cityController,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      key: const ValueKey('discover-filter-profession'),
                      label: 'Profession',
                      hint: 'Toutes les professions',
                      controller: _professionController,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Situation matrimoniale', style: typography.label),
                    const SizedBox(height: AppSpacing.sm),
                    AppFilterChips(
                      items: maritalItems,
                      selectedIds: _maritalStatuses,
                      onToggled: (id) => _toggle(_maritalStatuses, id),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Confession', style: typography.label),
                    const SizedBox(height: AppSpacing.sm),
                    AppFilterChips(
                      items: denominationItems,
                      selectedIds: _denominations,
                      onToggled: (id) => _toggle(_denominations, id),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Réinitialiser',
                      variant: AppButtonVariant.secondary,
                      onPressed: widget.onReset,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(label: 'Appliquer', onPressed: _apply),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeHeader extends StatelessWidget {
  const _RangeHeader({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;
    return Row(
      children: [
        Expanded(child: Text(label, style: typography.label)),
        Text(
          value,
          style: typography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
