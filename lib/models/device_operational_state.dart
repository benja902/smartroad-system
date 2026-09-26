/// Mirrors the firmware's `state` field (status topic). Published at most
/// once per status cycle (60s by default) — `preAlarm` in particular is
/// very unlikely to ever be observed live, since the grace period (10s by
/// default) is shorter than the status publish interval. Never build UI
/// that depends on catching `preAlarm` in real time.
enum DeviceOperationalState {
  boot,
  selftest,
  idle,
  preAlarm,
  sending,
  alertActive,
  cancelled,
  safeMode,
  unknown;

  static DeviceOperationalState parse(String? value) {
    switch (value) {
      case 'boot':
        return DeviceOperationalState.boot;
      case 'selftest':
        return DeviceOperationalState.selftest;
      case 'idle':
        return DeviceOperationalState.idle;
      case 'pre_alarm':
        return DeviceOperationalState.preAlarm;
      case 'sending':
        return DeviceOperationalState.sending;
      case 'alert_active':
        return DeviceOperationalState.alertActive;
      case 'cancelled':
        return DeviceOperationalState.cancelled;
      case 'safe_mode':
        return DeviceOperationalState.safeMode;
      default:
        return DeviceOperationalState.unknown;
    }
  }
}
