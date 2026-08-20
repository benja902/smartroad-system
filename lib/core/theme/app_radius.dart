import 'package:flutter/widgets.dart';

/// Border radius scale from docs/design_reference/DESIGN_SYSTEM.md.
class AppRadius {
  AppRadius._();

  static const double sm = 4;
  static const double defaultRadius = 8;
  static const double md = 12;

  /// Buttons and inputs.
  static const double lg = 16;

  /// Primary cards.
  static const double xl = 24;

  /// Status pills / fully rounded containers.
  static const double full = 9999;

  static BorderRadius get cardRadius => BorderRadius.circular(xl);
  static BorderRadius get buttonRadius => BorderRadius.circular(lg);
  static BorderRadius get pillRadius => BorderRadius.circular(full);
}
