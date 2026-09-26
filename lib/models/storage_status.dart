/// microSD status (docs/device_contract.md, `status.sd`).
class StorageStatus {
  final bool present;
  final int? totalMb;
  final int? freeMb;
  final int queuedEvents;

  const StorageStatus({
    required this.present,
    this.totalMb,
    this.freeMb,
    this.queuedEvents = 0,
  });

  factory StorageStatus.fromJson(Map<String, dynamic> json) {
    return StorageStatus(
      present: json['present'] as bool? ?? false,
      totalMb: (json['total_mb'] as num?)?.toInt(),
      freeMb: (json['free_mb'] as num?)?.toInt(),
      queuedEvents: (json['queued_events'] as num?)?.toInt() ?? 0,
    );
  }
}
