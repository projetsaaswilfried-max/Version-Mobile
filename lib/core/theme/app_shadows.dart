import 'package:flutter/widgets.dart';

/// Elevation shadow scale, invariant across themes.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x29000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
}
