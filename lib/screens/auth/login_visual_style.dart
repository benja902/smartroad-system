import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Screen-level presentation recipes, not a second global Design System.
/// No scope means provisionally approved Signature v2. DEV can compare all three.
enum LoginVisualVariant {
  current('Actual'),
  refined('A · Refined'),
  signature('B · Signature v2');

  const LoginVisualVariant(this.label);
  static const defaultVariant = LoginVisualVariant.signature;
  final String label;
  bool get experimental => this != current;
}

class LoginVisualScope extends InheritedWidget {
  const LoginVisualScope({
    super.key,
    required this.variant,
    required super.child,
    this.reviewAction,
  });

  final LoginVisualVariant variant;
  final Widget? reviewAction;
  static LoginVisualScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LoginVisualScope>();
  static LoginVisualVariant variantOf(BuildContext context) =>
      maybeOf(context)?.variant ?? LoginVisualVariant.defaultVariant;

  @override
  bool updateShouldNotify(LoginVisualScope oldWidget) =>
      variant != oldWidget.variant || reviewAction != oldWidget.reviewAction;
}

/// Provisional roles from the existing DS proposal, local to Login review.
/// Promote to AppTheme only after approval; neutral/space/radius/type reuse it now.
abstract final class LoginVisualStyle {
  static const navy = Color(0xFF031B3B);
  static const aqua = Color(0xFF14E0D3);
  static const teal = Color(0xFF006D68);
  static const error = Color(0xFFB52F34);
  static const heroSurface = Color(0xFFEDF3F5);
  static const selectedSurface = Color(0xFFCCF7F3);
  static const disabledSurface = Color(0xFFE3E8EF);
  static const disabledText = Color(0xFF526078);
  static const feedbackDuration = Duration(milliseconds: 120);

  static ThemeData theme(
    ThemeData base,
    LoginVisualVariant variant, {
    required bool reducedMotion,
  }) {
    final signature = variant == LoginVisualVariant.signature;
    final focus = signature ? teal : navy;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: BorderSide(color: color, width: width),
        );
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        primary: navy,
        onPrimary: Colors.white,
        secondary: teal,
        error: error,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: focus,
        selectionColor: selectedSurface,
        selectionHandleColor: focus,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: signature ? const Color(0xFFF5FAF9) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 18,
        ),
        border: border(AppColors.outline),
        enabledBorder: border(AppColors.outline),
        focusedBorder: border(focus, 2),
        errorBorder: border(error, 2),
        focusedErrorBorder: border(error, 2),
        disabledBorder: border(AppColors.outlineVariant),
        labelStyle: AppTypography.bodyMd.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurfaceVariant,
        ),
        floatingLabelStyle: TextStyle(
          color: focus,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        errorStyle: AppTypography.bodyMd.copyWith(color: error, height: 1.4),
        errorMaxLines: 4,
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.error)
              ? error
              : states.contains(WidgetState.focused)
              ? focus
              : AppColors.onSurfaceVariant,
        ),
        suffixIconColor: focus,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 56,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        constraints: const BoxConstraints(minHeight: 60),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              disabledBackgroundColor: disabledSurface,
              disabledForegroundColor: disabledText,
              minimumSize: const Size.fromHeight(60),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.buttonRadius,
              ),
              textStyle: base.textTheme.labelLarge!.copyWith(
                fontFamily: AppTypography.bodyLg.fontFamily,
                fontFamilyFallback: AppTypography.bodyLg.fontFamilyFallback,
                fontSize: 16,
                height: 1.5,
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
              ),
              animationDuration: reducedMotion
                  ? Duration.zero
                  : feedbackDuration,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? aqua.withValues(alpha: .22)
                    : states.contains(WidgetState.pressed)
                    ? Colors.white.withValues(alpha: .14)
                    : states.contains(WidgetState.hovered)
                    ? Colors.white.withValues(alpha: .08)
                    : null,
              ),
              side: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? const BorderSide(color: teal, width: 3)
                    : BorderSide.none,
              ),
            ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: focus,
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}
