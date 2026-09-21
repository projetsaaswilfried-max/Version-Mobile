import 'package:flutter/material.dart';

import '../../../../../core/config/app_assets.dart';
import '../../../../../core/widgets/widgets.dart';

class ThreadEmpty extends StatelessWidget {
  const ThreadEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      illustrationAsset: AppAssets.emptyChat,
      title: 'Pas encore de messages',
      detail: 'Envoie le premier message pour démarrer la conversation.',
    );
  }
}
