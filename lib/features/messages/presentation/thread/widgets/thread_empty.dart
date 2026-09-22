import 'package:flutter/material.dart';

import '../../../../../core/config/app_assets.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../domain/composer/thread_composer_mode.dart';
import '../../../domain/invite/invite_list_preview.dart';

class ThreadEmpty extends StatelessWidget {
  const ThreadEmpty({super.key, this.mode, this.peerName});

  final ThreadComposerMode? mode;
  final String? peerName;

  @override
  Widget build(BuildContext context) {
    final name = peerName?.trim() ?? '';
    final (title, detail) = switch (mode) {
      ThreadComposerMode.inviteActions => (
        kIncomingInviteTitle,
        '${incomingInviteHeadline(peerName)} Accepte pour ouvrir la '
            'conversation, ou refuse pour la retirer.',
      ),
      ThreadComposerMode.waitingPeer => (
        kOutgoingInvitePreview,
        name.isEmpty
            ? 'En attente de réponse. Tu pourras écrire dès que '
                'l\'invitation sera acceptée.'
            : 'En attente de la réponse de $name. Tu pourras écrire dès que '
                'l\'invitation sera acceptée.',
      ),
      _ => (
        'Pas encore de messages',
        'Envoie le premier message pour démarrer la conversation.',
      ),
    };

    return AppEmptyState(
      illustrationAsset: AppAssets.emptyChat,
      title: title,
      detail: detail,
    );
  }
}
