import 'accident_level.dart';
import 'event_status.dart';
import 'location_model.dart';

class AccidentEvent {
  final String id;
  final String deviceId;
  final String userId;
  final AccidentLevel level;
  final EventStatus status;
  final DateTime detectedAt;

  /// Only meaningful for level2 while pendingConfirmation: the wall-clock
  /// instant the countdown expires. Countdown UIs must always derive
  /// remaining time from this DateTime, never from a local Duration/Timer,
  /// so a future server-provided deadline is a drop-in replacement.
  final DateTime? deadline;

  final double? peakG;
  final LocationModel? location;
  final int contactsNotified;
  final bool rescueNotified;

  const AccidentEvent({
    required this.id,
    required this.deviceId,
    required this.userId,
    required this.level,
    required this.status,
    required this.detectedAt,
    this.deadline,
    this.peakG,
    this.location,
    this.contactsNotified = 0,
    this.rescueNotified = false,
  });

  AccidentEvent copyWith({
    String? id,
    String? deviceId,
    String? userId,
    AccidentLevel? level,
    EventStatus? status,
    DateTime? detectedAt,
    DateTime? deadline,
    double? peakG,
    LocationModel? location,
    int? contactsNotified,
    bool? rescueNotified,
  }) {
    return AccidentEvent(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      userId: userId ?? this.userId,
      level: level ?? this.level,
      status: status ?? this.status,
      detectedAt: detectedAt ?? this.detectedAt,
      deadline: deadline ?? this.deadline,
      peakG: peakG ?? this.peakG,
      location: location ?? this.location,
      contactsNotified: contactsNotified ?? this.contactsNotified,
      rescueNotified: rescueNotified ?? this.rescueNotified,
    );
  }

  /// True when this event is level2/level3 and not yet resolved — the
  /// signal that drives forcing navigation to a critical route.
  bool get isActiveCritical {
    if (level == AccidentLevel.level1) return false;
    return status != EventStatus.cancelled && status != EventStatus.closed;
  }

  factory AccidentEvent.fromJson(Map<String, dynamic> json) {
    return AccidentEvent(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      userId: json['userId'] as String,
      level: AccidentLevel.values.byName(json['level'] as String),
      status: EventStatus.values.byName(json['status'] as String),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
      deadline: json['deadline'] == null ? null : DateTime.parse(json['deadline'] as String),
      peakG: (json['peakG'] as num?)?.toDouble(),
      location: json['location'] == null
          ? null
          : LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      contactsNotified: json['contactsNotified'] as int? ?? 0,
      rescueNotified: json['rescueNotified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'userId': userId,
      'level': level.name,
      'status': status.name,
      'detectedAt': detectedAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'peakG': peakG,
      'location': location?.toJson(),
      'contactsNotified': contactsNotified,
      'rescueNotified': rescueNotified,
    };
  }
}
