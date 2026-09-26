# URBES — Contrato de datos del dispositivo (SDA / ESP32 · LilyGo T-SIM7600G-H)

Fuente de verdad: `manual-sda.html` (documento SDA-DOC-01, firmware 1.0.0). Este documento resume, para efectos de la app Flutter, exactamente qué campos llegan y de dónde, sin describir la arquitectura interna del firmware.

## Transporte real (no lo implementa Flutter)

El equipo habla **MQTT 3.1.1 sobre TLS** con un broker (HiveMQ Cloud), no HTTPS y no Firebase directo. Un **servicio puente** (Node.js, en `bridge/` — fuera de la app Flutter, se despliega por separado en Cloud Run, ver `bridge/README.md`) mantiene la conexión MQTT, escribe en Firebase Realtime Database, y proyecta las cancelaciones. Flutter **nunca** habla MQTT — solo lee/escribe en RTDB a través de los repositorios (`FirebaseEventRepository`, `FirebaseDeviceRepository`).

## Tópicos MQTT (referencia, los consume el puente)

| Tópico | Contenido | Cadencia |
|---|---|---|
| `sda/{id}/availability` | `online`/`offline`, texto plano, LWT | al conectar/desconectar |
| `sda/{id}/status` | estado completo del equipo | cada 60s (10-3600 configurable) |
| `sda/{id}/event` | choque, vuelco, SOS, cancelación, técnico | por evento |
| `sda/{id}/position` | posición GNSS | 30s en marcha / 300s detenido |
| `sda/{id}/diag` | diagnóstico ampliado | cada hora / bajo demanda |

## Esquema en Realtime Database (lo que escribe el puente, lo que lee Flutter)

```
devices/{deviceId}          → último status.* (ver DeviceStatus más abajo) + online + lastSeen
events/{deviceId_seq}       → un evento por (deviceId, seq) — ver AccidentEvent más abajo
vehicles/{vehicleId}        → administrado por la app, no por el firmware
users/{uid}                 → administrado por la app
```

## Mensaje de evento (`AccidentEvent`)

Payload real publicado en `sda/{id}/event` (choque grave, ejemplo del manual):

```json
{
  "id": "SDA-A4C138", "type": "crash", "seq": 143,
  "ts": "2026-08-19T14:32:07Z", "time_src": "gnss", "uptime_s": 48213,
  "vehicle_label": "Camioneta 04", "contact_phone": "+51987654321",
  "severity": "grave",
  "detection": { "peak_g": 38.40, "delta_v_kmh": 24.10, "duration_ms": 62,
                 "axis_peak": "y", "rollover": false, "tilt_deg": 12.5, "gyro_max_dps": 145.0 },
  "position": { "fix": true, "lat": -9.930833, "lon": -76.241944, "alt_m": 1894.0,
                "speed_kmh": 0.0, "heading": 218.0, "hdop": 1.1, "sats": 9, "fix_age_s": 3 },
  "device": { "battery_v": 4.02, "rssi_dbm": -73, "operator": "Claro PE",
              "uptime_s": 48213, "sd": true, "degraded": false },
  "queued": false
}
```

### Campos que vienen del firmware (verbatim)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | texto | id del dispositivo |
| `type` | texto | `crash`\|`rollover`\|`sos`\|`cancel`\|`test`\|`power_loss`\|`low_battery`\|`booted` |
| `seq` | entero | identidad del evento junto con `id`. **Un evento `cancel` tiene su propio `seq`, distinto del evento que anula.** |
| `ts` | texto ISO8601 o `null` | hora real del hecho; `null` si el equipo no tenía hora |
| `time_src` | texto | `gnss`\|`network`\|`ntp`\|`uptime`\|`none` |
| `uptime_s` | entero | segundos desde el arranque |
| `vehicle_label` | texto opcional | configurado en el equipo |
| `contact_phone` | texto opcional | configurado en el equipo |
| `severity` | texto | `leve`\|`moderado`\|`grave`\|`none`. Solo relevante para `crash`/`rollover` |
| `detection` | objeto opcional | solo en `crash`/`rollover` |
| `position` | objeto opcional | se omite si nunca hubo fix |
| `device` | objeto | snapshot de diagnóstico al momento del evento |
| `queued` | booleano | `true` = reenvío diferido desde la cola del equipo; el evento ya ocurrió, posiblemente hace horas |
| `cancels_seq` | entero, solo en `cancel` | **el `seq` del evento ORIGINAL que se anula** — no es el `seq` propio del evento `cancel` |
| `reason`, `elapsed_s` | solo en `cancel` | motivo y segundos transcurridos desde el evento original |

### Campos que agrega el puente (backend), no el firmware

| Campo | Notas |
|---|---|
| `receivedAt` | timestamp del servidor al escribir |
| `userId` | denormalizado desde `vehicles/{deviceId}.ownerId`, para poder consultar por usuario sin join del lado del cliente |
| `cancelledBySeq`, `cancelledAt` | **proyectados sobre el nodo del evento ORIGINAL** (clave `deviceId_cancelsSeq`, no `deviceId_seq` del propio `cancel`) cuando llega un `cancel` que lo referencia. Requiere escritura idempotente/`merge` — si el `cancel` llega antes que el evento original (MQTT no garantiza orden), el `merge` sobre la misma clave hace que se autocorrijan sin importar el orden de llegada |

### El único campo que la app puede escribir

| Campo | Notas |
|---|---|
| `acknowledged` | el usuario marcó "Ya lo vi" en la app. Es la única escritura que las reglas de seguridad permiten desde el cliente |

Clave de deduplicación en RTDB: **`{deviceId}_{seq}`** (equivalente al `{id}-{seq}` del manual). Una reentrega del mismo evento (QoS 1, o reenvío desde la cola) escribe sobre la misma clave y no duplica.

## Mensaje de estado (`DeviceStatus`)

Payload real publicado en `sda/{id}/status`:

```json
{
  "id": "SDA-A4C138", "ts": "2026-08-19T14:30:00Z", "state": "idle", "fw": "1.0.0",
  "sensors": {
    "adxl375":   { "ok": true, "addr": "0x53", "peak_g_60s": 1.40 },
    "lsm6ds3tr": { "ok": true, "addr": "0x6A", "tilt_deg": 3.1, "gyro_max_dps": 12.0 },
    "pcf8574":   { "ok": true, "addr": "0x20" }
  },
  "inputs":  { "sos": false, "cancel": false },
  "outputs": { "led_red": false, "led_green": true, "buzzer": false },
  "sd":      { "present": true, "total_mb": 15200, "free_mb": 14980, "queued_events": 0 },
  "modem":   { "registered": true, "rssi_dbm": -73, "tech": "LTE", "operator": "Claro PE" },
  "gnss":    { "fix": true, "lat": -9.930833, "lon": -76.241944, "alt_m": 1894.0,
               "speed_kmh": 42.3, "heading": 218.0, "hdop": 1.1, "sats": 9, "fix_age_s": 2 },
  "power":   { "battery_v": 4.02, "charging": true, "vin_ok": true },
  "system":  { "uptime_s": 48213, "heap_free": 148320, "reset_reason": "POWERON", "wifi_ap_clients": 0 }
}
```

`state` (`boot`\|`selftest`\|`idle`\|`pre_alarm`\|`sending`\|`alert_active`\|`cancelled`\|`safe_mode`) es el estado operativo del propio equipo — **no** el estado de un evento. Como `status` se publica cada 60s por defecto y `pre_alarm` dura ~10s por defecto, es muy improbable observar `pre_alarm` en vivo — ninguna pantalla debe depender de capturarlo a tiempo.

`online`/`lastSeen` **no** vienen de este mensaje — vienen del tópico separado `availability` (semántica LWT: `offline` significa que se cayó el enlace de datos, no que el equipo dejó de vigilar; sigue detectando y guarda en microSD mientras tanto).

`pcf8574` (expansor de botones/LED/buzzer) es un componente crítico según el manual — sin él no hay botones, LED ni buzzer, aunque la detección y la publicación siguen funcionando.

## Lo que Flutter NO hace

- No decide si hubo un accidente ni con qué severidad — eso lo decide el firmware.
- No escribe en `status.*` (sensores, red, GNSS, alimentación) — son de solo lectura para la app.
- No confirma ni cancela alertas — esas acciones son físicas en el equipo (botones SOS/CANCELAR) y llegan a Flutter como eventos (`type: cancel`), nunca como una acción que la app origina.
- Solo puede escribir `acknowledged` sobre un evento existente.

## Requisito para quien construya el puente (fuera de este repo)

- Escribir `events/{deviceId}_{seq}` con `merge`/idempotencia — nunca sobrescribir el nodo completo, para que una cancelación desordenada (llega antes que el evento original) se autocorrija cuando el evento original llegue después.
- Denormalizar `userId` en cada evento desde `vehicles/{deviceId}.ownerId` al momento de escribir.
- Proyectar `cancelledBySeq`/`cancelledAt` sobre la clave del evento **original** (`deviceId_cancelsSeq`), nunca sobre la clave del propio evento `cancel`.
