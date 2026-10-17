import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../presentation/premium_scene/premium_closure_motion.dart';
import 'login_form_parts.dart';
import 'login_visual_style.dart';
import '../../core/theme/app_spacing.dart';

/// Only presentation of slots created by LoginScreen, never a second form.
class PremiumLoginForm extends StatelessWidget {
  const PremiumLoginForm({
    super.key,
    required this.parts,
    required this.progress,
    required this.translationScale,
  });
  final LoginFormParts parts;
  final ValueListenable<double> progress;
  final double translationScale;
  @override
  Widget build(BuildContext context) {
    final variant = LoginVisualScope.variantOf(context);
    final experimental = variant.experimental;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PremiumLoginEntrance(
          progress: progress,
          start: 4090,
          translationScale: translationScale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bienvenido.',
                style: AppTypography.displayLg.copyWith(
                  fontSize: 32,
                  height: experimental ? 1.2 : 1.3,
                  letterSpacing: experimental ? -.8 : 0,
                  color: const Color(0xFF031B3B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                experimental
                    ? 'El estado y las alertas de tu vehículo, en un solo lugar.'
                    : 'Consulta el estado de tu vehículo\ny sus alertas.',
                style: AppTypography.bodyMd.copyWith(
                  fontSize: experimental ? 16 : 15,
                  height: experimental ? 1.5 : 23 / 15,
                  color: const Color(0xFF44474D),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: experimental ? AppSpacing.md : 32),
        PremiumLoginEntrance(
          progress: progress,
          start: 4130,
          translationScale: translationScale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              parts.email,
              SizedBox(height: experimental ? 20 : 12),
              parts.password,
              if (parts.error != null) ...[
                const SizedBox(height: 12),
                parts.error!,
              ],
            ],
          ),
        ),
        SizedBox(height: experimental ? AppSpacing.md : 32),
        PremiumLoginEntrance(
          progress: progress,
          start: 4170,
          translationScale: translationScale,
          child: parts.submit,
        ),
      ],
    );
  }
}

class PremiumLoginEntrance extends StatelessWidget {
  const PremiumLoginEntrance({
    super.key,
    required this.progress,
    required this.start,
    required this.translationScale,
    required this.child,
  });
  final ValueListenable<double> progress;
  final double start, translationScale;
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: progress,
    child: child,
    builder: (context, value, child) {
      final p = PremiumClosureMotion.easeOut(
        PremiumClosureMotion.phase(value * 2600, start, start + 240),
      );
      return ExcludeFocus(
        excluding: p <= 0,
        child: IgnorePointer(
          ignoring: p <= 0,
          child: ExcludeSemantics(
            excluding: p <= 0,
            child: Transform.translate(
              offset: Offset(0, 6 * translationScale * (1 - p)),
              child: Opacity(opacity: p, child: child),
            ),
          ),
        ),
      );
    },
  );
}
