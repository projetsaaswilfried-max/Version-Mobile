import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'app_avatar_placeholder.dart';
import 'app_network_image.dart';

/// Carte portrait pour grilles 2 colonnes (résultats de recherche, favoris,
/// qui m'aime) : photo pleine carte, dégradé sombre en bas, nom + sous-titre
/// en blanc superposés — cf. mockup fourni par le porteur produit.
class AppProfileGridCard extends StatelessWidget {
  const AppProfileGridCard({
    super.key,
    required this.title,
    this.photoUrl,
    this.subtitle,
    this.semanticLabel,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? photoUrl;
  final String? subtitle;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final typography = context.typography;

    return ClipRRect(
      borderRadius: AppRadius.xlRadius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              photoUrl == null
                  ? AppAvatarPlaceholder(
                      name: title,
                      borderRadius: AppRadius.xlRadius,
                    )
                  : AppNetworkImage(
                      url: photoUrl!,
                      semanticLabel: semanticLabel ?? title,
                    ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              if (trailing != null)
                Positioned(top: AppSpacing.sm, right: AppSpacing.sm, child: trailing!),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: typography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: typography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grille 2 colonnes standard pour [AppProfileGridCard].
class AppProfileGrid extends StatelessWidget {
  const AppProfileGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.controller,
    this.physics,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      physics: physics,
      padding: padding,
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.72,
      ),
      itemBuilder: itemBuilder,
    );
  }
}
