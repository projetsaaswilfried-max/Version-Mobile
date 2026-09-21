import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../home_tab.dart';

class HomeFloatingNavBar extends StatelessWidget {
  const HomeFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static double scrollClearance(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom +
        AppSpacing.xxxl +
        AppSpacing.xl +
        AppSpacing.sm;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        bottom > 0 ? bottom : AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.pillRadius,
          boxShadow: AppShadows.sm,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.82),
                borderRadius: AppRadius.pillRadius,
                border: Border.all(color: colors.border),
              ),
              child: Material(
                color: colors.surface.withValues(alpha: 0),
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth =
                          constraints.maxWidth / HomeTab.values.length;
                      return SizedBox(
                        height: AppSpacing.xxxl,
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              left: selectedIndex * itemWidth,
                              width: itemWidth,
                              top: 0,
                              bottom: 0,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xxs),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: AppRadius.pillRadius,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (final tab in HomeTab.values)
                                  Expanded(
                                    child: _NavItem(
                                      tab: tab,
                                      selected: selectedIndex == tab.index,
                                      onTap: () => onSelect(tab.index),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final HomeTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tint = selected ? colors.primary : colors.muted;
    return Tooltip(
      message: tab.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: tab.label,
        child: SizedBox(
          height: AppSpacing.xxxl,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Center(
              child: Icon(
                tab.icon,
                size: AppSpacing.xl + AppSpacing.xs,
                color: tint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
