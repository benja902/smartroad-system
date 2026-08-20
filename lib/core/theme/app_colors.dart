import 'package:flutter/material.dart';

/// Design system source of truth: docs/design_reference/DESIGN_SYSTEM.md.
///
/// NOTE: DESIGN_SYSTEM.md contains two different color sets — a YAML
/// frontmatter (e.g. primary: #041632) and a prose "semantic" section
/// (e.g. Primary/Navy: #1B2B48). This file follows the PROSE values for
/// all brand/status colors, per product decision. Do not "fix" these back
/// to the frontmatter hex values. Frontmatter neutrals are reused only for
/// surface/elevation tokens that the prose section doesn't define.
class AppColors {
  AppColors._();

  // Brand / semantic colors (prose section of DESIGN_SYSTEM.md).
  static const Color primary = Color(0xFF1B2B48); // Navy — nav, headers, primary actions
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF2ECC71); // "URBES Operativo", connected, all-clear
  static const Color warning = Color(0xFFF39C12); // "Posible Accidente" / Nivel 2

  /// Darkened amber for high-contrast Nivel 2 primary actions (e.g.
  /// "Necesito ayuda ahora"), matching the design reference's dark
  /// tertiary-container accent. Coral (critical) stays exclusive to Nivel 3.
  static const Color warningStrong = Color(0xFFB8720C);
  static const Color critical = Color(0xFFE74C3C); // "ALERTA DE ACCIDENTE" / Nivel 3 only

  // Neutrals.
  static const Color background = Color(0xFFF8F9FA);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // Surface/elevation neutrals borrowed from DESIGN_SYSTEM.md frontmatter
  // (not covered by the prose semantic section).
  static const Color onSurface = Color(0xFF1B1B1E);
  static const Color onSurfaceVariant = Color(0xFF44474D);
  static const Color outline = Color(0xFF75777E);
  static const Color outlineVariant = Color(0xFFC5C6CE);
  static const Color surfaceDim = Color(0xFFDBD9DC);

  // Overlay backdrop for modals/bottom sheets: 40% opacity navy.
  static Color overlayBackdrop = primary.withValues(alpha: 0.4);

  // Chips/badges: semantic color at 15% opacity background, full-strength text.
  static Color chipBackground(Color semantic) => semantic.withValues(alpha: 0.15);
}
