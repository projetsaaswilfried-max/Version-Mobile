import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_skeleton_box.dart';

class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Column(
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
    Widget bar({required double height, double? width}) {
      return AppSkeletonBox(
        width: width,
        height: height,
        borderRadius: AppRadius.smRadius,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppSkeletonBox(
                width: AppSpacing.xxxl,
                height: AppSpacing.xxxl,
                shape: BoxShape.circle,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: bar(height: AppSpacing.lg)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          bar(height: AppSpacing.md),
          const SizedBox(height: AppSpacing.sm),
          bar(height: AppSpacing.md, width: 180),
          const SizedBox(height: AppSpacing.md),
          bar(height: 160),
        ],
      ),
    );
  }
}
