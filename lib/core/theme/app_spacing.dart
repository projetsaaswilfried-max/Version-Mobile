/// Spacing scale, invariant across themes.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard tappable height for primary/secondary CTAs.
  static const double buttonHeight = 52;

  /// Minimum tappable height for text fields and select triggers.
  static const double inputHeight = 52;

  /// Placeholder widths for skeleton text bars.
  static const double skeletonTitleWidth = 140;
  static const double skeletonMetaWidth = 100;

  /// Max height of a modal sheet, as a fraction of the screen.
  static const double sheetMaxHeightFactor = 0.9;
}
