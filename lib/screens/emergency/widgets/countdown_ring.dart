import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Circular countdown that always derives remaining time from a wall-clock
/// [deadline] — never decrements a local counter. This means the ring is
/// correct even after the app is backgrounded and resumed, and a future
/// server-provided deadline is a drop-in replacement with no widget change.
class CountdownRing extends StatefulWidget {
  final DateTime startedAt;
  final DateTime deadline;
  final VoidCallback onExpired;

  const CountdownRing({
    super.key,
    required this.startedAt,
    required this.deadline,
    required this.onExpired,
  });

  @override
  State<CountdownRing> createState() => _CountdownRingState();
}

class _CountdownRingState extends State<CountdownRing> {
  Timer? _ticker;
  bool _expiredFired = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    final remaining = widget.deadline.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      _ticker?.cancel();
      if (!_expiredFired) {
        _expiredFired = true;
        widget.onExpired();
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.deadline.difference(DateTime.now());
    final total = widget.deadline.difference(widget.startedAt);
    final fraction = total.inMilliseconds <= 0
        ? 0.0
        : (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final secondsLeft = remaining.isNegative ? 0 : (remaining.inMilliseconds / 1000).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(200.0, 280.0);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: fraction,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.chipBackground(AppColors.warning),
                  valueColor: const AlwaysStoppedAnimation(AppColors.warning),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$secondsLeft',
                    style: AppTypography.displayLg.copyWith(color: AppColors.warning, fontSize: 64, height: 1),
                  ),
                  const SizedBox(height: 4),
                  Text('SEGUNDOS', style: AppTypography.labelSm.copyWith(color: AppColors.outline)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
