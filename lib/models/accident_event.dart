import 'accident_event_type.dart';
import 'accident_severity.dart';
import 'detection_data.dart';
import 'event_device_snapshot.dart';
import 'gnss_position.dart';

DateTime? _parseEventTimestamp(Object? value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  if (value is num) {
    if (value == 0 || !value.isFinite) return null;
    try {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    } on Error {
      return null;
    }
  }
  return null;
}

// Historical rows may contain malformed optional snapshots from the old bridge.
T? _parseOptionalBlock<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  if (value is! Map) return null;
  try {
    return parse(Map<String, dynamic>.from(value));
  } on TypeError {
    return null;
  } on FormatException {
    return null;
  }
}

GnssPosition _parseEventPosition(Map<String, dynamic> json) {
  final lat = json['lat'];
  final lon = json['lon'];
  if (lat is! num || lon is! num || !lat.isFinite || !lon.isFinite ||
      lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    throw const FormatException('Invalid event position');
  }
  return GnssPosition.fromJson(json);
}

/// An accident-system event, shaped to match exactly what the firmware
/// publishes (via the MQTT→backend bridge) per docs/device_contract.md —
/// not an app-invented abstraction. Fields are grouped by where they come
/// from; see the doc comments on each group.
class AccidentEvent {
  // --- From the firmware, verbatim ---
  final String deviceId;
  final AccidentEventType type;
  final int seq;
  final DateTime? ts;
  final String? timeSrc;
  final int? uptimeS;
  final String? vehicleLabel;
  final String? contactPhone;
  final AccidentSeverity severity;

  /// Only present on crash/rollover.
  final DetectionData? detection;

  /// Omitted if the device never obtained a position.
  final GnssPosition? position;

  /// Device diagnostics snapshot at the moment of the event.
  final EventDeviceSnapshot? device;

  /// true when this message is a delayed republish from the device's
  /// offline queue — the event already happened, possibly hours ago.
  final bool queued;

  /// Only present on `type == cancel`: the `seq` of the event being
  /// annulled. Note this event's own `seq` (above) is a distinct number —
  /// a cancel is its own message, not a mutation of the original.
  final int? cancelsSeq;
  final String? reason;
  final int? elapsedS;

  // --- Added by the backend/bridge (not from the firmware) ---
  /// First server receipt of the original. Older rows can lack this field.
  final DateTime? receivedAt;

  /// Last material enrichment, when recorded by the backend.
  final DateTime? updatedAt;

  /// Denormalized from vehicles/{deviceId}.ownerId at write time, so the
  /// app can query a user's events cheaply without a client-side join.
  final String userId;

  /// Vehicle resolved by the backend from the active device association.
  /// Optional while historical events still contain only [userId].
  final String? vehicleId;

  /// Set by the bridge, projected onto THIS event's node when a `cancel`
  /// event referencing it (cancelsSeq == this.seq) arrives. Written via an
  /// idempotent/merge write keyed by deviceId+cancelsSeq — see
  /// docs/device_contract.md.
  final int? cancelledBySeq;
  final DateTime? cancelledAt;

  /// Effective personal state after repository projection. The stored global
  /// field is read only as a legacy fallback; new writes use userIncidentState.
  final bool acknowledged;

  const AccidentEvent({
    required this.deviceId,
    required this.type,
    required this.seq,
    this.ts,
    this.timeSrc,
    this.uptimeS,
    this.vehicleLabel,
    this.contactPhone,
    this.severity = AccidentSeverity.none,
    this.detection,
    this.position,
    this.device,
    this.queued = false,
    this.cancelsSeq,
    this.reason,
    this.elapsedS,
    required this.receivedAt,
    this.updatedAt,
    required this.userId,
    this.vehicleId,
    this.cancelledBySeq,
    this.cancelledAt,
    this.acknowledged = false,
  });

  /// Dedup key convention used as the RTDB node key: `deviceId_seq`.
  String get dedupKey => '${deviceId}_$seq';

  AccidentEvent copyWith({
    int? cancelledBySeq,
    DateTime? cancelledAt,
    bool? acknowledged,
  }) {
    return AccidentEvent(
      deviceId: deviceId,
      type: type,
      seq: seq,
      ts: ts,
      timeSrc: timeSrc,
      uptimeS: uptimeS,
      vehicleLabel: vehicleLabel,
      contactPhone: contactPhone,
      severity: severity,
      detection: detection,
      position: position,
      device: device,
      queued: queued,
      cancelsSeq: cancelsSeq,
      reason: reason,
      elapsedS: elapsedS,
      receivedAt: receivedAt,
      updatedAt: updatedAt,
      userId: userId,
      vehicleId: vehicleId,
      cancelledBySeq: cancelledBySeq ?? this.cancelledBySeq,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  factory AccidentEvent.fromJson(String dedupKey, Map<String, dynamic> json) {
    return AccidentEvent(
      deviceId: json['id'] as String? ?? json['deviceId'] as String,
      type: AccidentEventType.parse(json['type'] as String?),
      seq: (json['seq'] as num).toInt(),
      ts: _parseEventTimestamp(json['ts']),
      timeSrc: json['time_src'] as String?,
      uptimeS: (json['uptime_s'] as num?)?.toInt(),
      vehicleLabel: json['vehicle_label'] as String?,
      contactPhone: json['contact_phone'] as String?,
      severity: AccidentSeverity.parse(json['severity'] as String?),
      detection: _parseOptionalBlock(json['detection'], DetectionData.fromJson),
      position: _parseOptionalBlock(json['position'], _parseEventPosition),
      device: _parseOptionalBlock(json['device'], EventDeviceSnapshot.fromJson),
      queued: json['queued'] as bool? ?? false,
      cancelsSeq: (json['cancels_seq'] as num?)?.toInt(),
      reason: json['reason'] as String?,
      elapsedS: (json['elapsed_s'] as num?)?.toInt(),
      receivedAt: json['receivedAt'] is num
          ? DateTime.fromMillisecondsSinceEpoch((json['receivedAt'] as num).toInt())
          : null,
      updatedAt: json['updatedAt'] is num
          ? DateTime.fromMillisecondsSinceEpoch((json['updatedAt'] as num).toInt())
          : null,
      userId: json['userId'] as String? ?? '',
      vehicleId: json['vehicleId'] as String?,
      cancelledBySeq: (json['cancelledBySeq'] as num?)?.toInt(),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((json['cancelledAt'] as num).toInt()),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': deviceId,
      'type': type.name,
      'seq': seq,
      'ts': ts?.toIso8601String(),
      'time_src': timeSrc,
      'uptime_s': uptimeS,
      'vehicle_label': vehicleLabel,
      'contact_phone': contactPhone,
      'severity': severity.name,
      'detection': detection?.toJson(),
      'position': position?.toJson(),
      'device': device?.toJson(),
      'queued': queued,
      'cancels_seq': cancelsSeq,
      'reason': reason,
      'elapsed_s': elapsedS,
      'receivedAt': receivedAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'userId': userId,
      'vehicleId': vehicleId,
      'cancelledBySeq': cancelledBySeq,
      'cancelledAt': cancelledAt?.millisecondsSinceEpoch,
      'acknowledged': acknowledged,
    };
  }
}
