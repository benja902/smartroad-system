# URBES — Contrato de datos del dispositivo (ESP32 / LilyGO T-SIM7000G)

Este documento define exactamente qué debe escribir el firmware en Firebase Realtime Database. Es un contrato de datos, no de arquitectura de firmware: el ESP32 decide localmente si hubo un accidente y con qué nivel; Firebase y Flutter solo observan y reaccionan a lo que el dispositivo escribe. Ni Flutter ni Firebase ejecutan el algoritmo de detección.

Base de datos: `smartroad-system-3b23e-default-rtdb` (Firebase Realtime Database).

Transporte: HTTPS (REST API de Realtime Database) sobre SIM7000G. No se usa MQTT en esta fase.

## Estructura general

```
users/{uid}
vehicles/{vehicleId}
devices/{deviceId}/
  status/
  hardware/
  network/
  gnss/
  location/
events/{eventId}
```

`users/` y `vehicles/` los gestiona la app (Flutter), no el firmware. El firmware solo escribe bajo `devices/{deviceId}/...` y crea nuevos nodos en `events/`.

## `devices/{deviceId}/status`

Estado general del dispositivo. El firmware debe actualizar esto en cada heartbeat (frecuencia sugerida: cada 30-60s, o al cambiar cualquier valor).

| Campo | Tipo | Descripción |
|---|---|---|
| `online` | boolean | El dispositivo está encendido y reportando. |
| `monitoring` | boolean | El algoritmo de detección de accidentes está activo. |
| `lastSeen` | number | Timestamp Unix en milisegundos del último reporte. |

## `devices/{deviceId}/hardware`

Diagnóstico de los sensores físicos.

| Campo | Tipo | Descripción |
|---|---|---|
| `adxl375Connected` | boolean | Acelerómetro ADXL375 responde correctamente. |
| `lsm6ds3Connected` | boolean | IMU LSM6DS3 responde correctamente. |
| `sim7000Connected` | boolean | Módulo SIM7000G responde correctamente. |

## `devices/{deviceId}/network`

Estado de la conexión celular.

| Campo | Tipo | Descripción |
|---|---|---|
| `cellularConnected` | boolean | Hay conexión de datos celular activa. |
| `networkType` | string | Uno de: `"none"`, `"cellular2g"`, `"cellular3g"`, `"cellular4g"`, `"wifi"`. |
| `signalStrength` | number | Barras de señal, entero de 0 a 4. |

## `devices/{deviceId}/gnss`

Estado del posicionamiento satelital.

| Campo | Tipo | Descripción |
|---|---|---|
| `available` | boolean | El módulo GNSS está encendido y accesible. |
| `fix` | boolean | Hay un fix de posición válido actualmente. |

## `devices/{deviceId}/location`

Última posición conocida del vehículo. Solo se actualiza cuando hay `fix` válido.

| Campo | Tipo | Descripción |
|---|---|---|
| `latitude` | number | Grados decimales. |
| `longitude` | number | Grados decimales. |
| `displayName` | string \| null | Nombre legible del lugar, si el dispositivo puede resolverlo (opcional — puede omitirse y dejar que el backend/app lo resuelva más adelante). |
| `updatedAt` | number | Timestamp Unix en milisegundos de este fix. |

## `events/{eventId}`

Un evento por cada detección de impacto. `{eventId}` lo genera el firmware (recomendado: `push()` de la REST API de RTDB, que genera IDs ordenables por tiempo) o puede ser un ID propio único por dispositivo+timestamp.

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | string | Igual a la key del nodo (duplicado dentro del valor para facilitar lecturas planas). |
| `deviceId` | string | ID de este dispositivo. |
| `userId` | string | UID del propietario del vehículo (el firmware lo conoce por configuración/aprovisionamiento). |
| `level` | string | Uno de: `"level1"`, `"level2"`, `"level3"`. Decidido localmente por el firmware. |
| `status` | string | Uno de: `"detected"`, `"pendingConfirmation"`, `"confirmed"`, `"cancelled"`, `"emergencyActive"`, `"closed"`. Ver reglas por nivel abajo. |
| `detectedAt` | number | Timestamp Unix en milisegundos del impacto. |
| `deadline` | number \| null | Solo para `level2`: `detectedAt + 15000` (ms). `null` para `level1`/`level3`. |
| `peakG` | number \| null | Aceleración pico registrada, en G. |
| `location` | object \| null | Mismo formato que `devices/{deviceId}/location`, capturado en el momento del evento. |
| `contactsNotified` | number | Cuántos contactos de emergencia fueron notificados hasta el momento. |
| `rescueNotified` | boolean | Si se notificó a servicios de rescate/SAMU (fase futura; el firmware puede dejarlo en `false` por ahora). |

### Reglas por nivel al crear el evento

- **Nivel 1**: crear con `status: "detected"`, `deadline: null`. El firmware no necesita actualizarlo después salvo diagnóstico adicional.
- **Nivel 2**: crear con `status: "pendingConfirmation"`, `deadline: detectedAt + 15000`. La app (Flutter) es responsable de mostrar el countdown y, según la acción del usuario o el vencimiento del plazo, actualizar `status` a `"confirmed"`/`"emergencyActive"` o `"cancelled"`. El firmware **no** debe sobrescribir `status` una vez que el usuario haya interactuado — debe limitarse a observar el valor si necesita reaccionar (p. ej. encender una sirena).
- **Nivel 3**: crear directamente con `status: "emergencyActive"`. Sin `deadline`, sin paso intermedio.

El cierre del incidente (`status: "closed"`) lo dispara la app o un operador — el firmware no debe cerrarlo automáticamente salvo que se defina lo contrario en una fase posterior.

## Autenticación del dispositivo (pendiente de definir)

Este documento no fija todavía cómo se autentica el ESP32 ante Firebase (token de dispositivo, secreto de base de datos legado, o un custom token emitido por un backend). Es una decisión de la fase de hardware, no bloquea el desarrollo de Flutter. Las reglas de seguridad actuales (`database.rules.json`) exigen `auth != null` para leer/escribir bajo `devices/` y `events/` — el mecanismo concreto de autenticación del firmware se definirá cuando se aborde la integración real del ESP32.

## Lo que Flutter NO hace

- No decide si hubo un accidente ni con qué severidad.
- No escribe en `devices/{deviceId}/hardware`, `network`, ni `gnss` — esos nodos son de solo lectura para la app.
- Sí puede escribir en `events/{eventId}` para transiciones de estado que dependen del usuario (confirmar, cancelar, cerrar) dentro de los límites descritos arriba.
