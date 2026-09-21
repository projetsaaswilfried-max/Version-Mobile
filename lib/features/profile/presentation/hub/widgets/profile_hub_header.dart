import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/entities/profile_hub.dart';

class ProfileHubHeader extends StatelessWidget {
  const ProfileHubHeader({
    super.key,
    required this.hub,
    required this.onViewPublicProfile,
    required this.onEdit,
  });

  final ProfileHub hub;
  final VoidCallback onViewPublicProfile;
  final VoidCallback onEdit;

  static const double _avatarRadius = AppSpacing.xxxl - AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typography = context.typography;
    final photoUrl = hub.photoUrl;
    final avatarSize = _avatarRadius * 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surface,
                  border: Border.all(color: colors.primary, width: 2.5),
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: avatarSize,
                    height: avatarSize,
                    child: photoUrl == null
                        ? AppAvatarPlaceholder(
                            name: hub.displayName,
                            circle: true,
                            iconSize: AppSpacing.xxl,
                          )
                        : AppNetworkImage(
                            url: photoUrl,
                            semanticLabel: hub.displayName,
                          ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Tooltip(
                  message: 'Modifier mon profil',
                  child: Material(
                    color: colors.primary,
                    shape: CircleBorder(
                      side: BorderSide(color: colors.surface, width: 2),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEdit,
                      child: SizedBox(
                        width: AppSpacing.xxl,
                        height: AppSpacing.xxl,
                        child: Icon(
                          Icons.edit_outlined,
                          color: colors.onScrim,
                          size: AppSpacing.md + AppSpacing.xxs,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  hub.displayName,
                  style: typography.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (hub.isVerified) ...[
                const SizedBox(width: AppSpacing.xs),
                const AppVerifiedBadge(),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: colors.chipBackground,
            borderRadius: AppRadius.pillRadius,
            child: InkWell(
              onTap: onViewPublicProfile,
              borderRadius: AppRadius.pillRadius,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: AppSpacing.lg,
                      color: colors.textPrimary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Voir mon profil public',
                      style: typography.label.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
