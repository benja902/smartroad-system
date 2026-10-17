import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'premium_vehicle.dart';

/// D's beacon, ending before departure. All units here are web phone pixels.
class BeaconState {
  const BeaconState(
    this.opacity,
    this.lift,
    this.offset,
    this.scale,
    this.reaction,
    this.waveOpacity,
  );
  final double opacity, lift, scale, reaction, waveOpacity;
  final Offset offset;
  double get shadowOpacity => (.11 - .02 * lift) * opacity;
  double get shadowRx => 10 - .8 * lift;
  double get shadowRy => 4 - .3 * lift;
  double get waveRx => 10 + 12 * reaction;
  double get waveRy => 4 + 5 * reaction;
}

class PremiumBeaconMotion {
  static Offset get anchor => PremiumVehicleMotion.project(236, 13, 26);
  static Offset get foot => PremiumVehicleMotion.project(236, 13, 0);
  static Offset nose(double ms) {
    final p = PremiumVehicleMotion.atMilliseconds(ms);
    return PremiumVehicleMotion.project(
      p.x + 44 * math.cos(p.angle),
      p.y + 44 * math.sin(p.angle),
    );
  }

  static final int encounterMilliseconds = _encounter();
  static int get endMilliseconds => encounterMilliseconds + 280;
  static int _encounter() {
    for (var ms = 0; ms <= 2000; ms++) {
      if ((nose((600 + ms).toDouble()) - foot).distance <= 16) return 600 + ms;
    }
    return 2600;
  }

  static final Offset direction = _direction();
  static Offset _direction() {
    final p = PremiumVehicleMotion.atMilliseconds(
      encounterMilliseconds.toDouble(),
    );
    final delta =
        PremiumVehicleMotion.project(
          p.x + math.cos(p.angle),
          p.y + math.sin(p.angle),
        ) -
        PremiumVehicleMotion.project(p.x, p.y);
    return delta / delta.distance;
  }

  static double _phase(double ms, double start, double end) =>
      ((ms - start) / (end - start)).clamp(0.0, 1.0);
  static BeaconState atMilliseconds(double ms) {
    final now = ms.clamp(0.0, endMilliseconds.toDouble());
    final entry = _phase(now, 720, 960),
        opacity = 1 - math.pow(1 - entry, 3).toDouble();
    final hover = _phase(now, 960, 2160);
    final lift = hover < .5
        ? PremiumVehicleMotion.ease(hover * 2)
        : 1 - PremiumVehicleMotion.ease(hover * 2 - 1);
    final reaction = _phase(
      now,
      encounterMilliseconds.toDouble(),
      endMilliseconds.toDouble(),
    );
    final amplitude = math.pow(math.sin(math.pi * reaction), 2).toDouble();
    return BeaconState(
      opacity,
      lift,
      Offset(
        3 * amplitude * direction.dx,
        -2 * lift + 3 * amplitude * direction.dy,
      ),
      1 + .035 * amplitude,
      reaction,
      .65 * amplitude,
    );
  }
}
