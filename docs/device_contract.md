# Contrato de integración del dispositivo SDA

## Fuente de verdad

Este documento contiene únicamente el contrato que el software de SmartRoad necesita conocer para integrar el SDA.

- La fuente técnica vigente y versionada del dispositivo es `manual-sda (4).html`.
- `manual-sda.html` y cualquier manual anterior son históricos. Ante contradicciones, prevalece `manual-sda (4).html`.
- Firebase Realtime Database (RTDB) es el backend de datos actual. Cualquier referencia del manual a Firestore describe una posibilidad de integración, no una decisión de arquitectura de SmartRoad.
- Los detalles no especificados por el manual se dejan expresamente pendientes; no deben inferirse ni fijarse como contrato.

## Flujos soportados

Flujo principal:

`SDA → MQTT/HiveMQ → consumidor MQTT persistente en Google Cloud → Firebase RTDB → Flutter/FCM`

Flujo de contingencia:

`SDA → RockBLOCK/Iridium → Ground Control → webhook HTTP en Google Cloud → Firebase RTDB → Flutter/FCM`

El consumidor MQTT y el webhook HTTP son componentes separados. Ambos transportes deben converger en un mismo incidente canónico sin duplicar el incidente ni sus notificaciones.

## MQTT

El SDA usa MQTT 3.1.1 sobre TLS. El cliente usa un identificador fijo y sesión persistente (`cleanSession = false`).

### Topics

| Topic | Dirección respecto del SDA | QoS | Retained | Uso |
|---|---|---:|---|---|
| `sda/{id}/availability` | publica | 1 | sí | Disponibilidad mediante conexión y Last Will |
| `sda/{id}/status` | publica | 0 | sí | Estado operativo más reciente |
| `sda/{id}/event` | publica | 1 | no | Eventos y cancelaciones |
| `sda/{id}/position` | publica | 0 | no | Posición solicitada o reportada |
| `sda/{id}/diag` | publica | 0 | no | Diagnóstico solicitado |
| `sda/{id}/cmd` | recibe | 1 | no | Comandos dirigidos al dispositivo |
| `sda/{id}/cmd/resp` | publica | 1 | no | Respuesta a comandos |

Los comandos documentados son `ping`, `position` y `diag`. Son consultas opcionales; la aplicación no debe depender de ellos para recibir incidentes.

### Tipos de evento

Valores documentados:

- `crash`
- `rollover`
- `sos`
- `cancel`
- `test`
- `power_loss`
- `low_battery`
- `booted`

El backend debe conservar valores desconocidos para diagnóstico y compatibilidad futura, sin convertirlos automáticamente en emergencias.

### Severidad

Los niveles documentados son:

- `none`
- `leve`
- `moderado`
- `grave`

La severidad recibida forma parte del evento. Las reglas sobre destinatarios pertenecen al backend y al producto, no al firmware.

### Identidad, secuencia y tiempo

- El campo `id` del mensaje y el marcador `{id}` del topic representan el `deviceId` lógico del SDA.
- `seq` identifica el evento dentro del dispositivo.
- La clave de deduplicación MQTT es `(deviceId, seq)`.
- El manual indica que `seq` persiste entre reinicios. Este comportamiento debe validarse con el prototipo físico antes de depender de él como garantía absoluta.
- `ts` es la fecha/hora del dispositivo cuando existe una hora válida. Un valor ausente o no válido no debe sustituirse silenciosamente por una hora inventada; el backend debe conservar además su propia hora de recepción.

### Evento

Un evento puede contener, según el tipo y la disponibilidad de sensores:

- identidad: `id`, `seq`, `type`, `severity`, `ts` y, cuando corresponda, `time_src` y `uptime_s`;
- detección: aceleración pico, delta-V, inclinación y velocidad angular;
- posición: latitud, longitud, validez y antigüedad;
- dispositivo: batería y otros datos diagnósticos;
- `queued`: indica que el evento fue almacenado sin conectividad y transmitido posteriormente.

Los campos concretos deben conservar los nombres y unidades emitidos por el SDA. El backend debe aceptar eventos parciales y no interpretar la ausencia de posición como ausencia de incidente.

### Cancelación

Una cancelación es un evento propio:

- tiene su propio `seq`;
- usa `type: cancel`;
- referencia el evento cancelado mediante `cancels_seq`.

El backend debe aplicar la cancelación aunque llegue antes que el evento original y reconciliar ambos posteriormente.

### Estado

El topic de estado informa la última condición operativa conocida. Los estados documentados son:

- `boot`
- `selftest`
- `idle`
- `pre_alarm`
- `sending`
- `alert_active`
- `cancelled`
- `safe_mode`

Puede incluir datos como batería, conectividad, GNSS y sensores. La aplicación debe tratarlo como una instantánea retained, no como historial de incidentes. `pre_alarm` representa una cuenta regresiva local anterior al envío; no demuestra por sí solo que exista un incidente persistido en el backend.

### Posición

La posición puede acompañar a un evento o publicarse en el topic `position`. La posición válida del GNSS es la fuente preferida. La aplicación debe mostrar la calidad o antigüedad cuando el backend las conserve y no asumir precisión exacta.

### Disponibilidad

El topic retained `availability` representa `online` u `offline`. El estado `offline` puede publicarse mediante Last Will. Esta señal indica conectividad MQTT, no necesariamente el estado físico total del dispositivo ni cobertura Iridium.

## RockBLOCK / Iridium

RockBLOCK es el canal de contingencia para choques y volcaduras que no se confirman por los canales celulares dentro del intervalo documentado.

- El SDA espera aproximadamente 20 segundos la confirmación del mismo `seq` por PUBACK de MQTT o por aceptación del SMS en la red.
- Si ninguno de esos canales confirma, intenta un mensaje binario RockBLOCK.
- SOS, cancelación, corte de energía, batería baja, arranque y posición periódica no se envían por Iridium.
- La prueba satelital pagada usa la clase 127, requiere confirmación explícita y hace un solo intento.
- El flujo de emergencia no depende de una sesión USB.
- El dispositivo mantiene una sola ranura de emergencia pendiente.
- El reintento puede mantenerse hasta 24 horas.
- El canal RockBLOCK documentado es de salida; no debe asumirse recepción de comandos por Iridium.

### Payload binario Iridium

El payload útil documentado tiene 39 bytes, antes del checksum adicional exigido por el comando `AT+SBDWB`. Los enteros multibyte se codifican en big-endian.

| Offset | Bytes | Campo | Codificación |
|---:|---:|---|---|
| 0 | 1 | `magic` | `0xA7` |
| 1 | 1 | `version` | `0x01` |
| 2 | 1 | clase de evento | 1 choque, 2 volcadura, 3 ambos, 127 prueba manual |
| 3 | 1 | flags | bit 0 posición válida; bit 1 equipo degradado; bit 2 tiempo válido; bit 3 batería ≤ 3.5 V |
| 4 | 4 | `device_id` | FNV-1a de `deviceId` |
| 8 | 4 | `seq` | entero sin signo |
| 12 | 4 | tiempo | Unix UTC; 0 si no es válido |
| 16 | 4 | latitud | entero con signo, grados × 100000 |
| 20 | 4 | longitud | entero con signo, grados × 100000 |
| 24 | 2 | antigüedad GNSS | segundos, saturado en 65535 |
| 26 | 2 | aceleración pico | g × 100 |
| 28 | 2 | delta-V | km/h × 100 |
| 30 | 2 | inclinación | grados × 10 |
| 32 | 2 | velocidad angular máxima | grados/s |
| 34 | 2 | batería | milivoltios |
| 36 | 1 | severidad | 0–3 según codificación del firmware |
| 37 | 2 | CRC | CRC-16/CCITT-FALSE de los bytes 0–36 |

El checksum de `AT+SBDWB` se agrega para transferir el payload al módem y no forma parte de estos 39 bytes.

## Ground Control y webhook

El backend receptor debe:

1. autenticar la solicitud conforme al mecanismo de Ground Control;
2. aceptar únicamente IMEI previamente aprovisionados;
3. resolver el `deviceId` esperado y validar su hash FNV-1a;
4. validar longitud, `magic`, versión y CRC antes de procesar;
5. deduplicar el mensaje por `(imei, momsn)`;
6. converger el mensaje al incidente `(deviceId, seq)`;
7. responder HTTP 200 en menos de tres segundos una vez persistida de forma segura la recepción;
8. emitir la notificación solo por la primera recepción válida;
9. permitir que una copia MQTT posterior enriquezca el incidente sin volver a notificarlo.

El manual no define el esquema HTTP exacto del webhook de Ground Control, todos los nombres de sus campos ni el detalle criptográfico del JWT. Esos datos deben obtenerse y validarse con la documentación vigente del proveedor antes de implementar el endpoint.

Cuando el payload no contiene una posición GNSS válida, el backend puede conservar como referencia aproximada la ubicación CEP proporcionada por Iridium/Ground Control, claramente diferenciada de una posición GNSS.

## Deduplicación y convergencia

- MQTT: `(deviceId, seq)`.
- RockBLOCK/Ground Control: `(imei, momsn)`.
- Incidente canónico entre transportes: `(deviceId, seq)`.
- Una retransmisión no crea un incidente nuevo.
- Una recepción posterior puede completar campos faltantes y mejorar posición o métricas.
- Una actualización no debe revertir cancelaciones, acuses o notificaciones ya registradas.
- La persistencia en RTDB debe usar claves deterministas u operaciones idempotentes. El esquema final de nodos y campos se definirá en la fase de modelo de datos.

## Responsabilidades

- El firmware detecta, clasifica, secuencia, almacena y transmite eventos.
- El backend autentica, valida, deduplica, normaliza, reconcilia transportes, persiste y decide destinatarios.
- Flutter consume el estado autorizado, presenta incidentes y ubicación, y gestiona la experiencia de notificación.
- FCM entrega avisos; no es la fuente de verdad del incidente.
