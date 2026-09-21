import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_skeleton_box.dart';
import 'discover_card.dart';

class DiscoverSkeleton extends StatelessWidget {
  const DiscoverSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _SkeletonCard(),
          SizedBox(height: AppSpacing.lg),
          _SkeletonCard(),
          SizedBox(height: AppSpacing.lg),
          _SkeletonCard(),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.xlRadius,
        boxShadow: AppShadows.md,
        border: Border.all(color: colors.border.withValues(alpha: 0.65)),
        color: colors.surface,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xlRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AspectRatio(
              aspectRatio: DiscoverCard.photoAspectRatio,
              child: AppSkeletonBox(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeletonBox(
                          height: AppSpacing.xl,
                          width: AppSpacing.skeletonTitleWidth,
                          borderRadius: AppRadius.smRadius,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        AppSkeletonBox(
                          height: AppSpacing.md,
                          width: AppSpacing.skeletonMetaWidth,
                          borderRadius: AppRadius.smRadius,
                        ),
                      ],
                    ),
                  ),
                  const AppSkeletonBox(
                    width: AppSpacing.xxl,
                    height: AppSpacing.xxl,
                    shape: BoxShape.circle,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const AppSkeletonBox(
                    width: AppSpacing.xxl,
                    height: AppSpacing.xxl,
                    shape: BoxShape.circle,
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
