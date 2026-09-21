import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/widgets/widgets.dart';

class FeedEmptyState extends StatelessWidget {
  const FeedEmptyState({super.key, required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      illustrationAsset: AppAssets.emptyFeed,
      title: filtered
          ? 'Aucun post dans cette catégorie'
          : 'Aucun post pour le moment',
      detail: filtered
          ? 'Essaie une autre catégorie pour voir plus de contenu.'
          : 'Les publications de la communauté apparaîtront ici.',
    );
  }
}
