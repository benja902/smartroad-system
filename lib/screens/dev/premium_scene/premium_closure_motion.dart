import 'package:flutter/material.dart';

import 'premium_beacon_motion.dart';
import 'premium_vehicle.dart';

/// Exact D phone-artboard choreography. No auth/session/router responsibility.
class ClosureState {
  const ClosureState(
    this.symbol,
    this.symbolScale,
    this.lockup,
    this.lockupScale,
    this.wordOpacity,
    this.sceneY,
    this.shadowOpacity,
  );
  final Offset symbol, lockup;
  final double symbolScale, lockupScale, wordOpacity, sceneY, shadowOpacity;
  Offset get symbolOnPhone => lockup + symbol * lockupScale;
  Offset get wordBaselineOnPhone => lockup + const Offset(43, 11) * lockupScale;
}

class PremiumClosureMotion {
  static const durationMilliseconds = 4440;
  static double phase(double ms, double from, double to) =>
      ((ms - from) / (to - from)).clamp(0.0, 1.0);
  static double smooth(double p) => p * p * (3 - 2 * p);
  static double easeOut(double p) => 1 - (1 - p) * (1 - p) * (1 - p);
  static ClosureState atMilliseconds(double ms) {
    final now = ms.clamp(0.0, 4440.0);
    final flight = PremiumVehicleMotion.ease(phase(now, 2680, 3360)),
        u = 1 - flight;
    final origin = Offset(
      14 + .6 * PremiumBeaconMotion.anchor.dx,
      270 + .6 * PremiumBeaconMotion.anchor.dy,
    );
    final point =
        origin * (u * u * u) +
        const Offset(365, 440) * (3 * u * u * flight) +
        const Offset(131, 510) * (3 * u * flight * flight) +
        const Offset(131, 633) * (flight * flight * flight);
    final beacon = PremiumBeaconMotion.atMilliseconds(now);
    final delivery = smooth(phase(now, 3540, 4090));
    final remainder = 1 - delivery;
    return ClosureState(
      point + beacon.offset - const Offset(131, 633),
      (.3 + .3 * flight) * beacon.scale,
      Offset(
        42 + 89 * remainder * remainder * remainder,
        633 - 586 * smooth(delivery),
      ),
      1 - .375 * delivery,
      easeOut(phase(now, 1900, 2200)),
      270 - 199 * delivery,
      beacon.shadowOpacity * (1 - smooth(phase(now, 2680, 2800))),
    );
  }
}
