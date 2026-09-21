import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/widgets/widgets.dart';

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({
    super.key,
    this.hasActiveFilters = false,
    this.onClearFilters,
  });

  final bool hasActiveFilters;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    if (hasActiveFilters) {
      return AppEmptyState(
        illustrationAsset: AppAssets.emptyDiscover,
        title: 'Aucun profil ne correspond',
        detail:
            'Tes filtres ne renvoient aucun résultat. Élargis ou efface-les pour revoir la liste.',
        actionLabel: 'Effacer les filtres',
        actionVariant: AppButtonVariant.primary,
        onAction: onClearFilters,
      );
    }
    return const AppEmptyState(
      illustrationAsset: AppAssets.emptyDiscover,
      title: 'Aucun profil pour le moment',
      detail: 'Reviens bientôt - de nouveaux profils apparaissent régulièrement.',
    );
  }
}
