import 'package:flutter/material.dart';

import '../../../discover/presentation/discover_body.dart';
import '../widgets/home_floating_nav_bar.dart';

class DiscoverTabPage extends StatelessWidget {
  const DiscoverTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    // DiscoverBody porte son propre AppBar (titre + icônes recherche/filtres)
    // pour que ces icônes vivent dans la vraie toolbar, pas dans une rangée
    // séparée sous le titre.
    return DiscoverBody(
      bottomPadding: HomeFloatingNavBar.scrollClearance(context),
    );
  }
}
