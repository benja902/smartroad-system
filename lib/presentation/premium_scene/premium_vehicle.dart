import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'premium_scene_motion.dart';

part 'premium_vehicle_geometry.g.dart';

/// Exact port of VehicleMotion: distance in projected ground, heading in world.
class VehiclePose {
  const VehiclePose(this.x, this.y, this.angle);
  final double x, y, angle;
}

class PremiumVehicleMotion {
  static const duration = Duration(milliseconds: 2600);
  static double ease(double value) {
    final x = value.clamp(0.0, 1.0);
    return x * x * x * (10 + x * (-15 + 6 * x));
  }

  static Offset project(double x, double y, [double z = 0]) =>
      Offset(300 + math.sqrt(3) / 2 * (x - y), 48 + .5 * (x + y) - z);

  static final List<VehiclePose> _route = _buildRoute();
  static final List<double> _distances = _buildDistances();
  static double get routeLength => _distances.last;

  static List<VehiclePose> _buildRoute() {
    final points = <VehiclePose>[];
    for (var i = 0; i <= 120; i++) {
      points.add(VehiclePose(64 + 71 * i / 120, 205, 0));
    }
    for (var i = 1; i <= 600; i++) {
      final t = i / 600, u = 1 - t;
      points.add(
        VehiclePose(
          u * u * u * 135 +
              3 * u * u * t * 198 +
              3 * u * t * t * 235 +
              t * t * t * 235,
          u * u * u * 205 +
              3 * u * u * t * 205 +
              3 * u * t * t * 171 +
              t * t * t * 113,
          math.atan2(
            -6 * u * t * 34 - 3 * t * t * 58,
            3 * u * u * 63 + 6 * u * t * 37,
          ),
        ),
      );
    }
    for (var i = 1; i <= 120; i++) {
      points.add(VehiclePose(235, 113 - 43 * i / 120, -math.pi / 2));
    }
    return points;
  }

  static List<double> _buildDistances() {
    final result = <double>[0];
    for (var i = 1; i < _route.length; i++) {
      final a = _route[i - 1], b = _route[i];
      result.add(
        result.last + (project(a.x, a.y) - project(b.x, b.y)).distance,
      );
    }
    return result;
  }

  static VehiclePose at(double progress) {
    final d = progress.clamp(0.0, 1.0) * routeLength;
    var lo = 0, hi = _route.length - 1;
    while (lo + 1 < hi) {
      final mid = (lo + hi) >> 1;
      if (_distances[mid] < d) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final a = _route[lo], b = _route[hi];
    final f = (d - _distances[lo]) / (_distances[hi] - _distances[lo]);
    return VehiclePose(
      a.x + (b.x - a.x) * f,
      a.y + (b.y - a.y) * f,
      a.angle + (b.angle - a.angle) * f,
    );
  }

  static VehiclePose atMilliseconds(double ms) => at(ease((ms - 600) / 2000));
}

class _Point3 {
  const _Point3(this.x, this.y, this.z);
  final double x, y, z;
}

class _VehiclePart {
  _VehiclePart(
    this.points,
    this.normal,
    Color? fill,
    Color? stroke,
    double width,
    this.closed,
  ) : fillPaint = fill == null ? null : (Paint()..color = fill),
      strokePaint = stroke == null
          ? null
          : (Paint()
              ..color = stroke
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round);
  final List<_Point3> points;
  final _Point3 normal;
  final Paint? fillPaint, strokePaint;
  final bool closed;
}

/// One projected face. Exposed to compare the Dart renderer with JS fixtures.
class VehicleFace {
  const VehicleFace(this.id, this.visible, this.depth, this.points);
  final int id;
  final bool visible;
  final double depth;
  final List<Offset> points;
}

class PremiumVehiclePainter extends CustomPainter {
  PremiumVehiclePainter(this.progress, {this.reveal = false})
    : super(repaint: progress);
  final bool reveal;
  final ValueListenable<double> progress;
  static final _parts = _buildVehicleParts();
  static final _shadowPaint = Paint()..color = const Color(0x211B2B48);

  static List<VehicleFace> faces(VehiclePose pose) {
    final c = math.cos(pose.angle), s = math.sin(pose.angle);
    final result = <VehicleFace>[];
    for (var i = 0; i < _parts.length; i++) {
      final part = _parts[i], n = part.normal;
      var depth = 0.0;
      final points = <Offset>[];
      for (final p in part.points) {
        final x = pose.x + p.x * c - p.y * s, y = pose.y + p.x * s + p.y * c;
        // Preserve JS left-to-right accumulation, including coplanar ties.
        depth = depth + x + y + p.z;
        points.add(PremiumVehicleMotion.project(x, y, p.z));
      }
      result.add(
        VehicleFace(
          i,
          n.x * c - n.y * s + n.x * s + n.y * c + n.z > 1e-7,
          depth / points.length,
          points,
        ),
      );
    }
    result.sort((a, b) {
      // Coplanar faces can differ by ~1e-13 between JS and Dart. Stable ties
      // prevent microscopic rounding differences from changing paint order.
      final d = (a.depth * 1e9).round().compareTo((b.depth * 1e9).round());
      return d == 0 ? a.id.compareTo(b.id) : d;
    });
    return result;
  }

  static Path _path(List<Offset> points, bool closed) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (closed) path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 620, size.height / 430);
    canvas.save();
    canvas.translate(
      (size.width - 620 * scale) / 2,
      (size.height - 430 * scale) / 2,
    );
    canvas.scale(scale);
    final opacity = reveal
        ? PremiumSceneMotion.vehicleOpacity(progress.value * 2600)
        : 1.0;
    if (opacity < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(255, 255, 255, opacity),
      );
    }
    final pose = PremiumVehicleMotion.atMilliseconds(progress.value * 2600);
    final c = math.cos(pose.angle), s = math.sin(pose.angle);
    final shadow = List.generate(48, (i) {
      final a = 2 * math.pi * i / 48,
          x = 44 * math.cos(a),
          y = 23 * math.sin(a);
      return PremiumVehicleMotion.project(
        pose.x + x * c - y * s + 7,
        pose.y + x * s + y * c + 9,
      );
    });
    canvas.drawPath(_path(shadow, true), _shadowPaint);
    for (final face in faces(pose)) {
      if (!face.visible) continue;
      final part = _parts[face.id], path = _path(face.points, part.closed);
      if (part.fillPaint != null) canvas.drawPath(path, part.fillPaint!);
      if (part.strokePaint != null) canvas.drawPath(path, part.strokePaint!);
    }
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PremiumVehiclePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.reveal != reveal;
}
