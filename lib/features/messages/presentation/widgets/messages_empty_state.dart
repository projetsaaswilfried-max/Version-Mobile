import 'package:flutter/material.dart';

import '../../../../core/config/app_assets.dart';
import '../../../../core/widgets/widgets.dart';

class MessagesEmptyState extends StatelessWidget {
  const MessagesEmptyState({super.key, required this.filtered});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      illustrationAsset: AppAssets.emptyChat,
      title: filtered ? 'Aucun résultat' : 'Aucune conversation',
      detail: filtered
          ? 'Essaie un autre nom ou efface la recherche.'
          : 'Démarre une discussion depuis Découvrir.',
    );
  }
}
