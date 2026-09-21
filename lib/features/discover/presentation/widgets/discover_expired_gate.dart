import 'package:flutter/material.dart';

import 'discover_centered_message.dart';

class DiscoverExpiredGate extends StatelessWidget {
  const DiscoverExpiredGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const DiscoverCenteredMessage(
      title: 'Abonnement expiré',
      body:
          'Ton abonnement a expiré. Renouvelle-le pour retrouver '
          'l\'accès complet à Agapéo.',
      emphasizeTitle: true,
    );
  }
}
