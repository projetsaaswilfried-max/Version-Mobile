import 'package:flutter/material.dart';

import 'home_tab_placeholder.dart';

class DiscoverTabPage extends StatelessWidget {
  const DiscoverTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: HomeTabPlaceholder(title: 'Découvrir'),
    );
  }
}
