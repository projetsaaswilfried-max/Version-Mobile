import 'package:flutter/material.dart';

import 'home_tab_placeholder.dart';

class MessagesTabPage extends StatelessWidget {
  const MessagesTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: HomeTabPlaceholder(title: 'Messages'),
    );
  }
}
