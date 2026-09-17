import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsStubPage extends StatelessWidget {
  const NotificationsStubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            'Aucune notification pour le moment.',
            textAlign: TextAlign.center,
            style: context.typography.bodyLarge,
          ),
        ),
      ),
    );
  }
}
