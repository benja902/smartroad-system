import 'dart:math' as math;
import 'dart:ui' show Picture, PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'premium_vehicle.dart';
import 'premium_scene_motion.dart';
import 'premium_beacon_motion.dart';

part 'premium_scene_geometry.g.dart';
part 'premium_beacon_painter.dart';

/// DEV increment 1: static approved D, before the vehicle encounter.
/// Illustration paths are prepared once; layout and movement stay separate.
enum PremiumScenePortion { all, beforeVehicle, afterVehicle }

class PremiumScenePainter extends CustomPainter {
  PremiumScenePainter({
    this.portion = PremiumScenePortion.all,
    this.motionProgress,
    this.hideBeacon = false,
  }) : super(repaint: motionProgress);
  final PremiumScenePortion portion;
  final ValueListenable<double>? motionProgress;
  final bool hideBeacon;

  static const designSize = Size(620, 430);
  static final List<_SceneLayer> _layers = _buildPremiumSceneGeometry();
  static final Map<String, Picture> _pictures = {
    for (final layer in _layers) layer.id: _record(layer),
  };

  static Picture _record(_SceneLayer layer) {
    final recorder = PictureRecorder(), canvas = Canvas(recorder);
    for (final shape in layer.shapes) {
      if (shape.transform != null) {
        canvas.save();
        canvas.transform(shape.transform!);
      }
      if (shape.fill != null) canvas.drawPath(shape.path, shape.fill!);
      if (shape.stroke != null) canvas.drawPath(shape.path, shape.stroke!);
      if (shape.transform != null) canvas.restore();
    }
    return recorder.endRecording();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (portion != PremiumScenePortion.afterVehicle) {
      canvas.drawColor(const Color(0xFFF8F9FA), BlendMode.srcOver);
    }
    final scale = math.min(size.width / 620, size.height / 430);
    canvas.save();
    canvas.translate(
      (size.width - 620 * scale) / 2,
      (size.height - 430 * scale) / 2,
    );
    canvas.scale(scale);
    final ms = motionProgress == null ? null : motionProgress!.value * 2600;
    var landscapeGroup = false;
    var pastVehicle = false;
    for (final layer in _layers) {
      if (hideBeacon &&
          (layer.id == 'target-shadow' || layer.id == 'brand-symbol')) {
        continue;
      }
      if (layer.id == 'layer-vehicle') {
        if (landscapeGroup) {
          canvas.restore();
          landscapeGroup = false;
        }
        pastVehicle = true;
        if (portion != PremiumScenePortion.all) continue;
      }
      if (portion == PremiumScenePortion.beforeVehicle && pastVehicle) continue;
      if (portion == PremiumScenePortion.afterVehicle && !pastVehicle) continue;
      if (ms != null && layer.id == 'layer-landscape') {
        canvas.saveLayer(
          null,
          Paint()
            ..color = Color.fromRGBO(
              255,
              255,
              255,
              PremiumSceneMotion.landscapeOpacity(ms),
            ),
        );
        landscapeGroup = true;
      }
      final motion = ms == null ? null : PremiumSceneMotion.layer(layer.id, ms);
      if (motion != null && motion.opacity <= 0) continue;
      canvas.save();
      if (motion != null) {
        canvas.translate(0, motion.dy);
        canvas.translate(motion.pivot.dx, motion.pivot.dy);
        canvas.scale(motion.scale);
        canvas.translate(-motion.pivot.dx, -motion.pivot.dy);
        if (motion.opacity < 1) {
          canvas.saveLayer(
            null,
            Paint()..color = Color.fromRGBO(255, 255, 255, motion.opacity),
          );
        }
      }
      canvas.drawPicture(_pictures[layer.id]!);
      if (motion != null && motion.opacity < 1) canvas.restore();
      canvas.restore();
    }
    if (landscapeGroup) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PremiumScenePainter oldDelegate) =>
      oldDelegate.portion != portion ||
      oldDelegate.hideBeacon != hideBeacon ||
      oldDelegate.motionProgress != motionProgress;
}

/// Presentation inside the existing DEV intro host, not a new route or login.
class PremiumScenePreview extends StatelessWidget {
  const PremiumScenePreview({
    super.key,
    this.vehicleProgress,
    this.sceneProgress,
    this.beaconProgress,
  });
  final ValueListenable<double>? vehicleProgress;
  final ValueListenable<double>? sceneProgress;
  final ValueListenable<double>? beaconProgress;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF8F9FA),
    child: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'URBES Premium · Escena D',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox.expand(
                child: vehicleProgress == null
                    ? CustomPaint(painter: PremiumScenePainter())
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: PremiumScenePainter(
                                portion: PremiumScenePortion.beforeVehicle,
                                motionProgress: sceneProgress,
                                hideBeacon: beaconProgress != null,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: PremiumVehiclePainter(
                                vehicleProgress!,
                                reveal: sceneProgress != null,
                              ),
                            ),
                          ),
                          RepaintBoundary(
                            child: CustomPaint(
                              painter: PremiumScenePainter(
                                portion: PremiumScenePortion.afterVehicle,
                                motionProgress: sceneProgress,
                                hideBeacon: beaconProgress != null,
                              ),
                            ),
                          ),
                          if (beaconProgress != null)
                            RepaintBoundary(
                              child: CustomPaint(
                                painter: PremiumBeaconPainter(beaconProgress!),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              beaconProgress != null
                  ? 'Baliza flotante D · Toca para cerrar'
                  : sceneProgress != null
                  ? 'Construcción por capas · Toca para cerrar'
                  : vehicleProgress == null
                  ? 'Escena estática · Toca para cerrar'
                  : 'Recorrido del vehículo · Toca para cerrar',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SceneLayer {
  const _SceneLayer(this.id, this.shapes);
  final String id;
  final List<_SceneShape> shapes;
}

class _SceneShape {
  _SceneShape(
    this.path,
    Color? fillColor,
    Color? strokeColor,
    double strokeWidth,
    this.transform,
    StrokeCap cap,
    StrokeJoin join,
  ) : fill = fillColor == null ? null : (Paint()..color = fillColor),
      stroke = strokeColor == null
          ? null
          : (Paint()
              ..color = strokeColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeCap = cap
              ..strokeJoin = join);

  final Path path;
  final Paint? fill;
  final Paint? stroke;
  final Float64List? transform;
}

// The approved road uses a single 9/10 dash pattern. Prepared once, before
// its ground transform, so line lengths follow the original SVG projection.
Path _laneMarkings(Path source) {
  final result = Path();
  for (final metric in source.computeMetrics()) {
    for (double offset = 0; offset < metric.length; offset += 19) {
      result.addPath(
        metric.extractPath(offset, math.min(offset + 9, metric.length)),
        Offset.zero,
      );
    }
  }
  return result;
}
