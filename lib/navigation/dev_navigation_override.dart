/// Dev-only escape hatch state: lets "Volver a /dev" on the critical
/// screen return to /dev without being immediately bounced back by the
/// router's forced redirect — but only for the specific event that was
/// active at that moment. A genuinely new critical event (different
/// dedupKey) still forces navigation to the emergency screen even while
/// /dev is open, matching real behavior. Unused in production (main.dart
/// never wires /dev, so this override is never read there).
class DevNavigationOverride {
  String? eventKey;
}
