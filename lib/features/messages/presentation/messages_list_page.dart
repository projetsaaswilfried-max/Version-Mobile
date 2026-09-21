import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'messages_body.dart';

class MessagesListPage extends StatelessWidget {
  const MessagesListPage({super.key, this.bottomPadding = AppSpacing.lg});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm),
          child: Text('Messages'),
        ),
      ),
      body: MessagesBody(bottomPadding: bottomPadding),
    );
  }
}
