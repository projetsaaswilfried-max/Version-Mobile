import 'package:flutter/material.dart';

import 'discover_centered_message.dart';

class DiscoverErrorState extends StatelessWidget {
  const DiscoverErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DiscoverCenteredMessage(
      title: message,
      actionLabel: 'Réessayer',
      onAction: onRetry,
    );
  }
}
