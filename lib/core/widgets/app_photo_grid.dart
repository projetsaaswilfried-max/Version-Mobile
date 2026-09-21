import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

class AppPhotoGrid extends StatelessWidget {
  const AppPhotoGrid({
    super.key,
    required this.paths,
    required this.maxSlots,
    required this.onAdd,
    required this.onRemoveAt,
    this.errorText,
    this.slotWidth = defaultSlotWidth,
    this.slotHeight = defaultSlotHeight,
  });

  static const double defaultSlotWidth = 110;
  static const double defaultSlotHeight = 140;

  final List<String> paths;
  final int maxSlots;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemoveAt;
  final String? errorText;
  final double slotWidth;
  final double slotHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final canAdd = paths.length < maxSlots;
    final closeIcon = AppSpacing.lg + AppSpacing.xxs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              errorText!,
              style: typography.bodySmall.copyWith(color: colors.error),
            ),
          ),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (var i = 0; i < paths.length; i++)
              SizedBox(
                width: slotWidth,
                height: slotHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.lgRadius,
                      child: Image.file(
                        File(paths[i]),
                        fit: BoxFit.cover,
                        cacheWidth:
                            (slotWidth * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                        cacheHeight:
                            (slotHeight *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round(),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        tooltip: 'Retirer la photo',
                        onPressed: () => onRemoveAt(i),
                        constraints: const BoxConstraints(
                          minWidth: AppSpacing.xxxl,
                          minHeight: AppSpacing.xxxl,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.standard,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.surface.withValues(
                            alpha: 0.92,
                          ),
                          foregroundColor: colors.textPrimary,
                          tapTargetSize: MaterialTapTargetSize.padded,
                        ),
                        icon: Icon(Icons.close, size: closeIcon),
                      ),
                    ),
                  ],
                ),
              ),
            if (canAdd)
              SizedBox(
                width: slotWidth,
                height: slotHeight,
                child: Material(
                  color: colors.primary.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.lgRadius,
                    side: BorderSide(
                      color: colors.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: AppRadius.lgRadius,
                    onTap: onAdd,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surface,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Icon(
                            Icons.add,
                            size: AppSpacing.xl,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
