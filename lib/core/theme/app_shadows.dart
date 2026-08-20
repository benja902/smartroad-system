import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Shadow / elevation rules from docs/design_reference/DESIGN_SYSTEM.md.
class AppShadows {
  AppShadows._();

  /// Soft diffused shadow for white cards, tinted with Primary Navy.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x141B2B48), // rgba(27, 43, 72, 0.08)
      offset: Offset(0, 4),
      blurRadius: 20,
    ),
  ];

  /// 40%-opacity navy backdrop for modals/bottom sheets.
  static Color overlayBackdrop = AppColors.primary.withValues(alpha: 0.4);
}
