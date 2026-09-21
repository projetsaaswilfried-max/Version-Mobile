import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_skeleton_box.dart';

class ProfileHubSkeleton extends StatelessWidget {
  const ProfileHubSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          const AppSkeletonBox(
            width: AppSpacing.xxxl * 1.5,
            height: AppSpacing.xxxl * 1.5,
            shape: BoxShape.circle,
          ),
          const SizedBox(height: AppSpacing.md),
          const AppSkeletonBox(
            height: AppSpacing.xl,
            width: AppSpacing.skeletonTitleWidth,
            borderRadius: AppRadius.smRadius,
          ),
          const SizedBox(height: AppSpacing.md),
          const AppSkeletonBox(
            height: AppSpacing.xxl + AppSpacing.sm,
            width: AppSpacing.skeletonTitleWidth + AppSpacing.xxxl,
            borderRadius: AppRadius.pillRadius,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var g = 0; g < 3; g++) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: AppSkeletonBox(
                height: AppSpacing.md,
                width: AppSpacing.skeletonMetaWidth,
                borderRadius: AppRadius.smRadius,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < 2; i++)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          AppSkeletonBox(
                            width: AppSpacing.xxl,
                            height: AppSpacing.xxl,
                            borderRadius: AppRadius.mdRadius,
                          ),
                          SizedBox(width: AppSpacing.md),
                          AppSkeletonBox(
                            height: AppSpacing.md,
                            width: AppSpacing.skeletonMetaWidth,
                            borderRadius: AppRadius.smRadius,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
