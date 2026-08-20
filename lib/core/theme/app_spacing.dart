/// Spacing scale from docs/design_reference/DESIGN_SYSTEM.md.
class AppSpacing {
  AppSpacing._();

  static const double base = 4;
  static const double xs = 8;
  static const double sm = 16;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 48;

  /// Global horizontal safe zone.
  static const double edgeMargin = 20;
  static const double gutter = 12;

  /// Soft cap on content width on large screens — a constraint, not a
  /// fixed width. Wrap content in ConstrainedBox(maxWidth: contentMaxWidth)
  /// centered, never force this width on narrow phones.
  static const double contentMaxWidth = 600;
}
