import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../models/accident_event.dart';
import '../models/accident_event_type.dart';

/// Non-blocking, dismissible card for AlertPresentation.attention events
/// (crash/rollover, severity moderado). Deliberately not a full-screen
/// interruption — the app has no real action to offer beyond what this
/// card already provides (acknowledge / view details), so forcing a
/// takeover would interrupt without purpose. See the alignment plan for
/// the full rationale — this is a UX judgment call, not something the
/// firmware dictates.
///
/// The live elapsed-seconds counter and icon pulse are app-side only —
/// they never synchronize with the device's own buzzer/prealarm timing
/// (that would need a real-time channel from the device the design
/// deliberately avoids). Their purpose is purely to make this card visibly
/// distinct from a static "leve" card, since distinguishing buzzer beep
/// patterns by ear alone is unreliable.
class AttentionBanner extends StatefulWidget {
  final AccidentEvent event;
  final VoidCallback onAcknowledge;
  final VoidCallback onViewDetails;

  const AttentionBanner({
    super.key,
    required this.event,
    required this.onAcknowledge,
    required this.onViewDetails,
  });

  @override
  State<AttentionBanner> createState() => _AttentionBannerState();
}

class _AttentionBannerState extends State<AttentionBanner> with SingleTickerProviderStateMixin {
  late final Timer _ticker;
  late final AnimationController _pulseController;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  void _updateElapsed() {
    final since = widget.event.ts ?? widget.event.receivedAt;
    final seconds = DateTime.now().difference(since).inSeconds;
    setState(() => _elapsedSeconds = seconds < 0 ? 0 : seconds);
  }

  @override
  void dispose() {
    _ticker.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _elapsedLabel {
    if (_elapsedSeconds < 60) return 'Hace $_elapsedSeconds s';
    final minutes = _elapsedSeconds ~/ 60;
    return 'Hace $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final title = event.type == AccidentEventType.rollover
        ? 'Posible volcadura detectada'
        : 'Posible accidente detectado';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.cardRadius,
        border: const Border(top: BorderSide(color: AppColors.warning, width: 4)),
        boxShadow: const [
          BoxShadow(color: Color(0x141B2B48), offset: Offset(0, 4), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _pulseController.drive(Tween(begin: 0.45, end: 1.0)),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.chipBackground(AppColors.warning), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber, color: AppColors.warning),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text(
                      _elapsedLabel,
                      style: AppTypography.labelSm.copyWith(color: AppColors.warning, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: widget.onViewDetails, child: const Text('Ver detalles')),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onAcknowledge,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
                  child: const Text('Ya lo vi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
