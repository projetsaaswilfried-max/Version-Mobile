import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_avatar_placeholder.dart';
import 'app_fullscreen_gallery.dart';
import 'app_network_image.dart';
import 'app_verified_badge.dart';

/// Community-kit profile hero: rounded portrait photo, no overlay.
class AppProfileHero extends StatelessWidget {
  const AppProfileHero({
    super.key,
    required this.photoUrls,
    required this.semanticName,
    this.aspectRatio = 4 / 5,
  });

  final List<String> photoUrls;
  final String semanticName;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = photoUrls.isEmpty ? null : photoUrls.first;
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadius.xlRadius,
        boxShadow: AppShadows.md,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.xlRadius,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: url == null
              ? AppAvatarPlaceholder(name: semanticName)
              : GestureDetector(
                  onTap: () => AppFullscreenGallery.open(
                    context,
                    photoUrls: photoUrls,
                    semanticName: semanticName,
                  ),
                  child: AppNetworkImage(url: url, semanticLabel: semanticName),
                ),
        ),
      ),
    );
  }
}

/// Name, age, city and optional trailing (score) under the hero.
class AppProfileIdentity extends StatelessWidget {
  const AppProfileIdentity({
    super.key,
    required this.displayName,
    this.ageLabel,
    this.city,
    this.subtitle,
    this.isVerified = false,
    this.trailing,
  });

  final String displayName;
  final String? ageLabel;
  final String? city;
  final String? subtitle;
  final bool isVerified;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: typography.headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (ageLabel != null && ageLabel!.isNotEmpty)
              Text(
                ' ($ageLabel)',
                style: typography.headline.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (isVerified) ...[
              const SizedBox(width: AppSpacing.xs),
              const AppVerifiedBadge(),
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
              Icon(
                Icons.location_on_outlined,
                size: AppSpacing.lg,
                color: colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  city!,
                  style: typography.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle!, style: typography.bodyMedium),
        ],
      ],
    );
  }
}

class AppProfileSection extends StatelessWidget {
  const AppProfileSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.typography.title),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Remaining photos under the hero, two columns.
class AppProfileGallery extends StatelessWidget {
  const AppProfileGallery({
    super.key,
    required this.photoUrls,
    required this.semanticName,
  });

  final List<String> photoUrls;
  final String semanticName;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photoUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: AppRadius.lgRadius,
          child: GestureDetector(
            onTap: () => AppFullscreenGallery.open(
              context,
              photoUrls: photoUrls,
              initialIndex: index,
              semanticName: semanticName,
            ),
            child: AppNetworkImage(
              url: photoUrls[index],
              semanticLabel: semanticName,
            ),
          ),
        );
      },
    );
  }
}
