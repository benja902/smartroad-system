import 'package:flutter/material.dart';

/// D clock, before any brand reaction/delivery. No second animation clock.
class SceneLayerMotion {
  const SceneLayerMotion(this.opacity, this.scale, this.dy, this.pivot);
  final double opacity, scale, dy;
  final Offset pivot;
}

class PremiumSceneMotion {
  static const completeMilliseconds = 955;
  static double phase(double ms, double start, double length) =>
      ((ms + 200 - start) / length).clamp(0.0, 1.0);
  static double easeOut(double x) => 1 - (1 - x) * (1 - x) * (1 - x);
  static double landscapeOpacity(double ms) => easeOut(phase(ms, 500, 280));
  static double vehicleOpacity(double ms) => phase(ms, 800, 180);

  static SceneLayerMotion layer(String id, double ms) {
    var start = 0.0, length = 1.0, dy = 0.0, scale = 1.0;
    var pivot = const Offset(300, 220);
    switch (id) {
      case 'layer-ground':
        start = 180;
        length = 340;
        scale = .985;
      case 'layer-road':
        start = 270;
        length = 380;
        scale = .992;
      case 'object-townhouse':
        start = 430;
        length = 400;
        dy = 8;
        scale = .985;
        pivot = const Offset(300, 120);
      case 'object-pavilion':
        start = 550;
        length = 360;
        dy = 6;
        scale = .985;
        pivot = const Offset(400, 250);
      case 'object-bench':
        start = 780;
        length = 260;
        dy = 3;
      case 'object-lamps':
        start = 840;
        length = 260;
        dy = 3;
      case 'object-tree-5':
        start = 580;
        length = 300;
        dy = 4;
        scale = .98;
      // Preserve hidden T4's slot (635 in HTML); do not compress staggering.
      case 'object-tree-4':
        start = 690;
        length = 300;
        dy = 4;
        scale = .98;
      case 'object-tree-0':
        start = 745;
        length = 300;
        dy = 4;
        scale = .98;
      case 'object-tree-1':
        start = 800;
        length = 300;
        dy = 4;
        scale = .98;
      case 'object-tree-2':
        start = 855;
        length = 300;
        dy = 4;
        scale = .98;
      default:
        return SceneLayerMotion(1, 1, 0, pivot);
    }
    final p = easeOut(phase(ms, start, length));
    return SceneLayerMotion(p, scale + (1 - scale) * p, dy * (1 - p), pivot);
  }
}
