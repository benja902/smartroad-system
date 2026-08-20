/// Marker value exposed via Provider so any screen can check whether the
/// /dev route is reachable in this build, without importing main_dev.dart
/// or duplicating the includeDevRoute flag.
class DevModeFlag {
  final bool enabled;

  const DevModeFlag(this.enabled);
}
