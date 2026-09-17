import 'package:flutter/material.dart';

import '../notifications/notifications_stub_page.dart';
import 'home_tab_placeholder.dart';

class FeedTabPage extends StatelessWidget {
  const FeedTabPage({super.key});

  static const int unreadCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fil'),
        actions: [
          IconButton(
            icon: unreadCount > 0
                ? Badge(
                    label: Text('$unreadCount'),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsStubPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: const HomeTabPlaceholder(title: 'Fil'),
    );
  }
}
