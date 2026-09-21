import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_staff_badge.dart';
import 'app_verified_badge.dart';

/// Gradient + identity over a photo, Datify card / fiche style.
class AppProfilePhotoOverlay extends StatelessWidget {
  const AppProfilePhotoOverlay({
    super.key,
    required this.displayName,
    this.ageLabel,
    this.city,
    this.isVerified = false,
    this.isStaff = false,
    this.trailing,
  });

  final String displayName;
  final String? ageLabel;
  final String? city;
  final bool isVerified;
  final bool isStaff;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final onScrim = colors.onScrim;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.scrim.withValues(alpha: 0),
            colors.scrim.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isStaff) ...[
              const AppStaffBadge(onScrim: true),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: typography.title.copyWith(color: onScrim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ageLabel != null && ageLabel!.isNotEmpty) ...[
                  Text(
                    ' ($ageLabel)',
                    style: typography.title.copyWith(
                      color: onScrim.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (isVerified) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const AppVerifiedBadge(onScrim: true),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
            if (city != null && city!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Icons.location_on_outlined,
                      size: AppSpacing.lg,
                      color: onScrim.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      city!,
                      style: typography.bodyMedium.copyWith(
                        color: onScrim.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
