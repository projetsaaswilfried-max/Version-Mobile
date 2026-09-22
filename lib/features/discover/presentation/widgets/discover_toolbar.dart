import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

/// Actions de la toolbar Découvrir (dans l'AppBar, à côté du titre) :
/// icône recherche (ouvre la page dédiée) et icône filtres (ouvre le
/// panneau sur place) — remplace l'ancien champ de recherche épinglé, qui
/// poussait le bottom nav quand le clavier s'ouvrait.
class DiscoverToolbar extends StatelessWidget {
  const DiscoverToolbar({
    super.key,
    required this.unlocked,
    required this.onSearchLocked,
    required this.onFiltersLocked,
    required this.onSearchTap,
    required this.onFiltersTap,
    this.filtersActive = false,
  });

  final bool unlocked;
  final VoidCallback onSearchLocked;
  final VoidCallback onFiltersLocked;
  final VoidCallback onSearchTap;
  final VoidCallback onFiltersTap;
  final bool filtersActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToolbarIcon(
            icon: Icons.search,
            tooltip: unlocked ? 'Rechercher' : 'Passe Premium pour rechercher',
            onTap: unlocked ? onSearchTap : onSearchLocked,
          ),
          _ToolbarIcon(
            icon: Icons.tune,
            tooltip: unlocked
                ? (filtersActive ? 'Filtres actifs' : 'Filtres')
                : 'Passe Premium pour filtrer',
            onTap: unlocked ? onFiltersTap : onFiltersLocked,
            showBadge: unlocked && filtersActive,
          ),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: showBadge ? colors.primary : colors.textPrimary,
          ),
          if (showBadge)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: AppSpacing.sm,
                height: AppSpacing.sm,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
