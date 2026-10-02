# Catálogo de identificadores de SmartRoad

## Propósito

Este documento define los identificadores que relacionan Firebase Authentication, RTDB, el SDA, MQTT y RockBLOCK/Iridium. No contiene valores reales, credenciales ni secretos.

Conocer cualquiera de estos identificadores no concede acceso. La autorización depende de Firebase Authentication, las asociaciones aprovisionadas por SmartRoad y las reglas del backend y RTDB.

## Catálogo

| Identificador | Quién lo genera | Autoridad | Lógico o físico | Sensibilidad | ¿Puede cambiar? | Dónde se usa | Deduplicación o autorización |
|---|---|---|---|---|---|---|---|
| `uid` | Firebase Authentication | Firebase Authentication | Lógico | Dato interno sensible; no es un secreto | Es estable durante la vida de la cuenta. Cambia si la identidad se recrea o migra | Perfil, rol, propiedad del vehículo y contactos autorizados | Autoriza el acceso del usuario; no deduplica incidentes |
| `vehicleId` | Provisión administrativa de SmartRoad | Backend y modelo autorizado en RTDB | Lógico | Dato interno asociado al vehículo; no es un secreto | Debe permanecer estable. Solo cambia mediante una migración controlada | Relación entre propietario, vehículo, SDA e incidentes | Delimita el acceso por asociación; no deduplica transportes |
| `deviceId` | Firmware SDA, derivado conforme al manual vigente | El SDA es autoridad al emitirlo; el registro del backend decide si se acepta y con qué vehículo se asocia | Identidad lógica derivada de un dispositivo físico | Identificador operativo protegido; no es una credencial | Cambia si se sustituye la placa o se reprovisiona la identidad del SDA | Topics y payloads MQTT, dispositivo, vehículo e incidentes | Integra la clave `(deviceId, seq)` y participa indirectamente en autorización mediante su asociación aprovisionada |
| `imei` | Fabricante y módulo RockBLOCK/Iridium | Iridium/Ground Control acredita el valor; el registro del backend decide si pertenece a la flota | Físico | Identificador operativo sensible; no es un secreto | Normalmente es inmutable para el módulo. Cambia al sustituir el RockBLOCK | Allowlist satelital y resolución del RockBLOCK hacia `deviceId` | Integra `(imei, momsn)` y autoriza la pertenencia del módulo a la flota |
| `seq` | Máquina de eventos del SDA | El SDA; el backend valida su uso y aplica las mitigaciones necesarias | Lógico y local al SDA | No es sensible por sí solo | Cambia con cada evento. El manual exige persistencia entre reinicios, pendiente de validación física | Eventos MQTT e Iridium, referencia `cancels_seq` y convergencia entre transportes | Deduplica únicamente junto con `deviceId`; no autoriza |
| `momsn` | RockBLOCK/Iridium al procesar un mensaje saliente | Iridium/Ground Control | Lógico y asociado a una entrega satelital | Metadata operativa; no es sensible por sí sola | Cambia entre entregas. Su rollover y ciclo exacto dependen de la especificación oficial pendiente | Webhook, reintentos y resolución de sesiones satelitales ambiguas | Deduplica únicamente junto con `imei`; no autoriza por sí solo |
| `(deviceId, seq)` | Backend al componer los valores emitidos por el SDA | Modelo canónico de SmartRoad | Clave lógica compuesta | Dato operativo protegido; no es un secreto | Es inmutable para un incidente aceptado; una corrección requiere migración explícita | Identidad canónica del incidente, persistencia RTDB y convergencia MQTT/Iridium | Clave principal de deduplicación de incidentes; hereda el alcance autorizado de las asociaciones del dispositivo |
| `(imei, momsn)` | Backend al componer los datos validados de Ground Control | Backend de recepción satelital, respetando la autoridad de Iridium sobre sus componentes | Clave lógica compuesta con un componente físico | Dato operativo sensible porque contiene el IMEI; no es un secreto | Es distinta para cada entrega y no debe reutilizarse deliberadamente | Registro de recepción, retries y auditoría del webhook | Clave de deduplicación satelital; la autorización se valida separadamente mediante la allowlist del IMEI |

## Reglas permanentes

- Ningún identificador funciona como contraseña, token o credencial.
- No se registran valores reales en documentación, fixtures, ejemplos ni logs destinados al repositorio.
- El backend valida asociaciones y allowlists; conocer un identificador no concede acceso.
- Las claves compuestas se construyen de forma determinista y se procesan mediante operaciones idempotentes.
- `uid` autoriza a una identidad autenticada solo dentro de las asociaciones y reglas que le correspondan.
- `deviceId` e `imei` identifican orígenes aprovisionados, pero no sustituyen la autenticación del transporte o del webhook.
- `seq` y `momsn` no son globalmente únicos por separado.
- Los datos mock del modo DEV deben usar valores evidentemente ficticios y permanecer separados de producción.

## Validaciones pendientes

- El checkpoint físico de `seq` determinará si es necesaria una política adicional contra colisiones por reinicio, sin cambiar la identidad canónica `(deviceId, seq)`.
- El checkpoint del SDA confirmará el `deviceId` del prototipo sin incorporarlo a este documento.
- El checkpoint RockBLOCK confirmará el IMEI sin incorporarlo a este documento.
- La especificación oficial de Ground Control deberá confirmar el ciclo y eventual rollover de MOMSN.
