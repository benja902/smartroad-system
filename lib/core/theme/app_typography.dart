import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography scale from docs/design_reference/DESIGN_SYSTEM.md.
/// Font family: Manrope throughout.
class AppTypography {
  AppTypography._();

  static TextStyle _manrope({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double letterSpacing = 0,
    Color color = AppColors.onSurface,
  }) {
    return GoogleFonts.manrope(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height / fontSize,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// Critical alerts only.
  static TextStyle displayLg = _manrope(fontSize: 32, fontWeight: FontWeight.w800, height: 40);
  static TextStyle displayLgMobile = _manrope(fontSize: 26, fontWeight: FontWeight.w800, height: 32);

  /// Card titles.
  static TextStyle headlineMd = _manrope(fontSize: 20, fontWeight: FontWeight.w700, height: 28);

  static TextStyle bodyLg = _manrope(fontSize: 16, fontWeight: FontWeight.w500, height: 24);
  static TextStyle bodyMd = _manrope(fontSize: 14, fontWeight: FontWeight.w400, height: 20);

  /// Secondary data labels, e.g. "DISPOSITIVO CONECTADO". Always ALL CAPS
  /// at the call site.
  static TextStyle labelSm = _manrope(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16,
    letterSpacing: 0.6, // 0.05em @ 12px
  );
}
