import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_skeleton_box.dart';

class MessagesSkeleton extends StatelessWidget {
  const MessagesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          _SkeletonRow(),
          _SkeletonRow(),
          _SkeletonRow(),
          _SkeletonRow(),
          _SkeletonRow(),
          _SkeletonRow(),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          const AppSkeletonBox(
            width: AppSpacing.xl * 2,
            height: AppSpacing.xl * 2,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeletonBox(
                  height: AppSpacing.md,
                  width: 140,
                  borderRadius: AppRadius.smRadius,
                ),
                const SizedBox(height: AppSpacing.sm),
                const AppSkeletonBox(
                  height: AppSpacing.sm,
                  width: 220,
                  borderRadius: AppRadius.smRadius,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
