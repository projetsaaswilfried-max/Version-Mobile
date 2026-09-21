import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_skeleton_box.dart';

class FeedCommentsSkeleton extends StatelessWidget {
  const FeedCommentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _CommentSkeletonRow(),
        SizedBox(height: AppSpacing.md),
        _CommentSkeletonRow(),
        SizedBox(height: AppSpacing.md),
        _CommentSkeletonRow(),
      ],
    );
  }
}

class _CommentSkeletonRow extends StatelessWidget {
  const _CommentSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeletonBox(
          width: AppSpacing.xl + AppSpacing.sm,
          height: AppSpacing.xl + AppSpacing.sm,
          shape: BoxShape.circle,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSkeletonBox(
                height: AppSpacing.md,
                width: AppSpacing.xxxl + AppSpacing.xl,
                borderRadius: AppRadius.smRadius,
              ),
              const SizedBox(height: AppSpacing.sm),
              const AppSkeletonBox(
                height: AppSpacing.xxl,
                borderRadius: AppRadius.mdRadius,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
