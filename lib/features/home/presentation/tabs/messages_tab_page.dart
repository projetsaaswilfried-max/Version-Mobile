import 'package:flutter/material.dart';

import '../../../messages/presentation/messages_list_page.dart';
import '../widgets/home_floating_nav_bar.dart';

class MessagesTabPage extends StatelessWidget {
  const MessagesTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MessagesListPage(
      bottomPadding: HomeFloatingNavBar.scrollClearance(context),
    );
  }
}
