import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../safety/presentation/widgets/profile_safety_sheet.dart';
import '../../domain/entities/discover_profile.dart';
import '../discover_controller.dart';

class DiscoverCard extends ConsumerWidget {
  const DiscoverCard({
    super.key,
    required this.profile,
    this.onTap,
    this.onLikePressed,
    this.onFavoritePressed,
  });

  /// Photo plane only - the white identity footer sits below.
  static const photoAspectRatio = 4 / 5;

  final DiscoverProfile profile;
  final VoidCallback? onTap;
  final VoidCallback? onLikePressed;
  final VoidCallback? onFavoritePressed;

  Future<void> _openSafetyMenu(BuildContext context, WidgetRef ref) async {
    final blocked = await ProfileSafetySheet.present(
      context: context,
      ref: ref,
      profileId: profile.id,
    );
    if (blocked && context.mounted) {
      await ref.read(discoverControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final typography = context.typography;
    final age = profile.ageLabel ?? profile.age?.toString();
    final confession = profile.traits.confession?.trim();
    final hasConfession = confession != null && confession.isNotEmpty;
    final hasCity = profile.city != null && profile.city!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.xlRadius,
          boxShadow: AppShadows.md,
          border: Border.all(color: colors.border.withValues(alpha: 0.65)),
        ),
        child: Material(
          color: colors.surface,
          borderRadius: AppRadius.xlRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: photoAspectRatio,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      profile.photoUrl == null
                          ? AppAvatarPlaceholder(
                              name: profile.displayName,
                              borderRadius: AppRadius.xlRadius,
                            )
                          : AppNetworkImage(
                              url: profile.photoUrl!,
                              semanticLabel: profile.displayName,
                            ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.scrim.withValues(alpha: 0),
                              colors.scrim.withValues(alpha: 0.22),
                            ],
                            stops: const [0.55, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (profile.isStaff) ...[
                              const AppStaffBadge(onScrim: true),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            _PhotoMenuButton(
                              onPressed: () => _openSafetyMenu(context, ref),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.displayName,
                                    style: typography.headline,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (age != null && age.isNotEmpty) ...[
                                  Text(
                                    ', $age',
                                    style: typography.headline.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                                if (profile.isVerified) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  const AppVerifiedBadge(),
                                ],
                              ],
                            ),
                            if (hasCity || hasConfession) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                [
                                  if (hasCity) profile.city!,
                                  if (hasConfession) confession,
                                ].join(' · '),
                                style: typography.bodyMedium.copyWith(
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CardAction(
                        icon: profile.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        active: profile.isLiked,
                        tooltip: 'Aimer ce profil',
                        onPressed: onLikePressed,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _CardAction(
                        icon: profile.isFavorited
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        active: profile.isFavorited,
                        tooltip: 'Mettre en favori',
                        onPressed: onFavoritePressed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoMenuButton extends StatelessWidget {
  const _PhotoMenuButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: 'Signaler ou bloquer',
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: colors.surface.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          elevation: 0,
          child: SizedBox(
            width: AppSpacing.xxl + AppSpacing.xs,
            height: AppSpacing.xxl + AppSpacing.xs,
            child: Icon(
              Icons.more_horiz,
              color: colors.textPrimary,
              size: AppSpacing.xl,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.active,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: active
              ? colors.primary.withValues(alpha: 0.12)
              : colors.chipBackground,
          shape: const CircleBorder(),
          child: SizedBox(
            width: AppSpacing.xxl + AppSpacing.xs,
            height: AppSpacing.xxl + AppSpacing.xs,
            child: Icon(
              icon,
              color: active ? colors.primary : colors.textSecondary,
              size: AppSpacing.lg + AppSpacing.xxs,
            ),
          ),
        ),
      ),
    );
  }
}
