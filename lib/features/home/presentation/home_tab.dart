import 'package:flutter/cupertino.dart';

enum HomeTab {
  feed('Fil', CupertinoIcons.square_grid_2x2_fill),
  discover('Découvrir', CupertinoIcons.compass_fill),
  messages('Messages', CupertinoIcons.chat_bubble_2_fill),
  profile('Profil', CupertinoIcons.person_fill);

  const HomeTab(this.label, this.icon);

  final String label;
  final IconData icon;
}
