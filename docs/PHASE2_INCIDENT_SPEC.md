# Fase 2, Bloque 2.1 — contrato canónico de incidentes

## Autoridad, propósito y punto de partida

Esta es la especificación de trabajo para el **primer bloque** de Fase 2. Su propósito es que recepciones de un mismo incidente SDA puedan validarse, identificarse y fusionarse sin perder cancelaciones, tiempos ni compatibilidad histórica. No declara que el modelo ya esté desplegado. Para el comportamiento **actual** prevalecen `bridge/index.js`, `bridge/event_writer.js`, `lib/models/accident_event.dart`, `lib/repositories/firebase/firebase_event_repository.dart` y sus pruebas. `docs/device_contract.md` y `manual-sda (4).html` son autoridad sobre el mensaje SDA; `docs/IMPLEMENTATION_PLAN.md` define qué sigue pendiente. `docs/RTDB_MODEL.md` distingue nodos actuales y objetivo.

**Hoy:** MQTT escribe `events/{deviceId}_{seq}` con `update()`. La asociación se consulta en `vehicles` por `deviceId`; el payload no se valida integralmente ni se compara `id` con el topic. El writer elimina del payload `vehicleId`, `acknowledged`, `cancelledBySeq` y `cancelledAt`; proyecta un `cancel` al original por `cancels_seq`, conservando también la fila `cancel`. El `receivedAt` actual se vuelve a escribir en cada entrega, incluso duplicados (lo confirman las pruebas del bridge). No escribe `updatedAt`, `status` global, `transports` ni calidad canónica de ubicación. No existen aún webhook Iridium, fusión MQTT/Iridium ni FCM. Flutter lee histórico por `userId` y nuevo por `vehicleId`, deduplica por `eventKey`, usa `ts` legible o `receivedAt` para ordenar y mantiene el reconocimiento propio en `userIncidentState`.

## Alcance del bloque

Definir y, **solo en una tarea posterior**, implementar incrementalmente el contrato de ingesta y persistencia compatible del único SDA: identidad, validación básica, tiempos diferenciados, fusión/idempotencia MQTT, cancelaciones y lectura de eventos existentes. Las pruebas de fusión de dos transportes podrán usar entradas sintéticas; **no** implican un webhook operativo. Fuera de alcance: modificar firmware, cuentas o reglas de Firebase real, migrar/destruir históricos, activar contactos, FCM, SMS, endpoint Ground Control, despliegue cloud y operaciones satelitales pagadas. No añadir un estado `partial`/`enriched` sin consumidor (`docs/INCIDENT_MODEL.md`).

## Esquema canónico lógico (objetivo; persistencia exacta por decidir)

La identidad es por **evento/ incidente**, no por entrega. `crash`, `rollover` y `sos` son incidentes; `cancel` modifica uno; `test`, `power_loss`, `low_battery`, `booted` y desconocidos no se convierten automáticamente en emergencias. Un placeholder creado por cancelación temprana puede carecer temporalmente de campos del original. “Obligatorio” significa para un **incidente aceptado completo**, salvo nota; no autoriza rechazar una recepción parcial útil sin la política abierta correspondiente.

| Campo lógico | Obligación | Procedencia y semántica |
|---|---|---|
| `eventKey` | Sí para persistir | Backend: composición nominal `${deviceId}_${seq}`; una clave por incidente nominal. |
| `deviceId` (`id` heredado) | Sí | MQTT: identidad declarada en el topic, contrastada con `id` del payload y la asociación; autenticación del publicador por verificar. Iridium: IMEI aprovisionado + hash FNV-1a verificado. Nunca derivarlo de otro vehículo. |
| `seq` | Sí | SDA; entero de secuencia del evento. El `cancel` tiene otro `seq` y referencia `cancels_seq`. Persistencia tras reinicio aún sin prueba física formal. |
| `type` | Sí para original | SDA; tipos según `device_contract.md`. Un placeholder de cancelación temprana puede no tenerlo hasta recibir el original. |
| `severity` | Según tipo; política exacta abierta | SDA; valores `none`, `leve`, `moderado`, `grave`; Iridium codifica 0–3. La tabla de equivalencia y exigencia por tipo deben verificarse. |
| `vehicleId` | Al resolver asociación | Backend administrativo; nunca aceptar del payload. Histórico sin este campo sigue legible por el propietario mediante `userId`. Un nuevo evento sin asociación no se atribuye silenciosamente. |
| `userId` | Compatibilidad temporal | Backend desde el propietario asociado, no del SDA. Conservación necesaria para la consulta histórica; no autoriza por sí solo. |
| `ts`, `time_src`, `uptime_s` | Opcionales | Tiempo y contexto declarados por el SDA; `ts` puede faltar o no ser fiable. No usarlo como reloj de recepción. |
| `receivedAt` | Sí para recepción válida persistida | Reloj del backend. **Objetivo ya definido:** primera recepción válida del incidente nominal, inmutable ante duplicados y enriquecimiento. Esto corrige el comportamiento actual de sobrescritura. |
| `updatedAt` | Si se incorpora cambio válido posterior | Reloj del backend; última incorporación válida. No existe hoy. Si una entrega duplicada sin cambio lo mueve o no es `DECISIÓN ABIERTA`. |
| `queued` | Opcional en entrada | Indicador del SDA de transmisión diferida, no nuevo incidente. Distinguir “no informado” de `false` en la política final (`DECISIÓN ABIERTA`). |
| `transports` / procedencia | Objetivo, formato abierto | Backend: registrar aportes MQTT e Iridium y, si procede, tiempos por entrega; no confundir `(imei,momsn)` con identidad del incidente. Nunca exponer IMEI al contacto. |
| `position` y calidad | Opcionales | GNSS SDA o CEP Ground Control, diferenciados por origen, validez y antigüedad. No crear coordenadas ficticias. |
| `detection`, `device` | Opcionales | Métricas y snapshot SDA; Iridium puede aportar un subconjunto cuantizado. Solo propietario, no proyección de contacto. |
| `status` global | Objetivo | `active`/`cancelled` según `docs/INCIDENT_MODEL.md`; no lo escribe hoy el bridge. Nunca inferir `active` si hay cancelación previa. |
| `cancelledBySeq`, `cancelledAt` | Si existe cancelación | `cancelledBySeq` proviene del `seq` de `cancel`; `cancelledAt` del backend. No aceptar estos campos del payload entrante. Evidencia persistente no reversible. |
| `acknowledged` | **No** forma parte del nuevo incidente global | Estado personal en `userIncidentState/{uid}/{eventKey}`. El campo global heredado solo se lee como fallback; el backend no lo reemplaza. |

El **esquema físico exacto**, conversión de campos binarios Iridium, estructura de `transports` y reglas de normalización de unidades requieren decisión/verificación antes de codificar. Mantener la ruta `events` y las claves actuales durante la transición, sin reescritura masiva.

## Transportes, identidad y tiempos

- MQTT: `sda/{deviceId}/event`, QoS 1, `id` y `seq` declarados por SDA. Se debe comprobar `id` frente al `deviceId` del topic **y** a la asociación autorizada antes de persistir. El bridge actual toma la clave del topic y no hace esa comprobación. El topic por sí solo no prueba la identidad del publicador; la garantía de autenticación del broker requiere verificación separada.
- Iridium: solo choques/volcaduras de contingencia (no SOS ni `cancel`), payload binario de 39 bytes del manual, `device_id` hash FNV-1a, `seq`, tiempo Unix **en segundos** o 0, posición y métricas cuantizadas. El webhook futuro autenticará la entrega, validará IMEI, longitud/versión/CRC/hash y deduplicará `(imei,momsn)` antes de converger en `(deviceId,seq)`. HTTP/JWT exactos dependen de la especificación vigente de Ground Control aún no obtenida.
- `ts` es **tiempo reportado por SDA**, opcional. La lectura Flutter actual acepta cadena ISO 8601 o número interpretado como **milisegundos**; `ts` inválido/ausente da `null` y usa `receivedAt` para presentación/orden. Un `0` numérico se convierte actualmente en época Unix, no en dato inválido. El contrato objetivo no debe inventar hora del SDA; tratamiento de cero, unidades en entradas MQTT y precedencia frente a tiempo Iridium son abiertos.
- `receivedAt` debe conservar la **primera** recepción válida del incidente nominal, incluida una recepción satelital parcial. Hoy el bridge lo sobrescribe. `updatedAt` expresará una actualización posterior válida, separado de `ts` y de cada marca de recepción de transporte. La definición exacta de “cambio válido” es abierta.
- `queued` informa que el SDA transmitió tarde. No altera `eventKey`, no retrocede `receivedAt`, no convierte `ts` en tiempo de ingesta ni demuestra que el vehículo aún esté activo. Una asociación histórica cerrada requiere tratamiento controlado, sin reasignación automática.

## Fusión, reintentos, cancelación y errores

**Invariantes fijadas:** la misma identidad nominal no crea dos incidentes visibles ni dos notificaciones; un duplicado o reintento no borra campos válidos previos, cancelaciones, acuses personales o marcadores de notificación; `userId`/`vehicleId` provienen de administración y no del payload; el `deviceId` original no cambia por reemplazo del SDA; datos técnicos/IMEI no llegan a contactos; una recepción parcial no se presenta como ubicación exacta si carece de ella. La convergencia Iridium↔MQTT debe enriquecer el mismo incidente, pero todavía no hay implementación ni prueba con webhook.

**Cancelación posterior:** `cancel` con `seq` propio y `cancels_seq` válido deja `cancelledBySeq`/`cancelledAt` en el original, sin convertir el registro `cancel` histórico en otro incidente visible. **Cancelación anterior:** crear/conservar evidencia mínima sobre la clave nominal del original y completarla después sin revertirla. La fila `cancel` existente se preserva durante la transición. Hoy esto está cubierto por pruebas locales del bridge para `crash`, `rollover` y `sos`; no demuestra aún concurrencia ni transacción atómica.

**Payload inválido:** se espera error controlado, sin escritura canónica ni notificación, para JSON malformado, identidad incompatible, `seq` inutilizable o campos fuera de política. Hoy `index.js` captura JSON/errores, pero `event_writer.js` puede escribir otros payloads sin validación. Tamaños/rangos/tipos precisos y destino de rechazos quedan abiertos. Una asociación ausente nunca debe fabricarse desde un `vehicleId` recibido; el writer actual aún escribe un evento sin `vehicleId` ni `userId`, conducta que requiere política antes de restringirla. Una colisión auténtica de `seq` no puede resolverse como duplicado por una simple diferencia de `ts`: se requiere criterio de detección y tratamiento que preserve el registro anterior y toda evidencia. No se debe eliminar un evento histórico para “corregirlo”.

Errores esperados para pruebas: transporte o JSON malformado, topic/payload discrepantes, asociación ausente/incompatible, tipo/severidad/medida fuera de contrato, duplicado idéntico, actualización parcial compatible, `seq` colisionado, cancelación con referencia inválida, entrega satelital repetida/corrupta. La política de rechazo, cuarentena y reintento según caso se decide antes de implementar escrituras reales.

## DECISIÓN ABIERTA — registrar resolución antes de implementar la rama afectada

| Decisión y por qué importa | Alternativas razonables e impacto |
|---|---|
| Esquema físico canónico y metadatos de transporte: no hay productor Iridium ni consumidores de `transports`/`updatedAt` hoy. | Añadir campos compatibles a `events` (menos migración, exige controlar conflictos) o subnodos de aportes por transporte (mejor auditoría, más reglas/lecturas). Fijar nombres/unidades y forma antes de escribir. |
| `ts` faltante, inválido, cero y numérico MQTT; `time_src` y hora Iridium. | Guardar raw y calidad separada (más trazabilidad) o normalizar a un único timestamp solo si se conoce unidad/fuente (más simple, riesgo de falsa precisión). Confirmar unidad firmware; no tratar cero como época válida sin decisión. |
| `updatedAt` ante duplicado idéntico y precisión/atomicidad de `receivedAt`. | Moverlo por cada recepción (audita actividad, cambia orden) o solo por cambio material (estabilidad, requiere comparación/transacción). Preservar primera recepción en ambos casos. |
| Merge de campos en conflicto, prioridad MQTT frente a Iridium y GNSS frente a CEP. | “Completar solo ausentes” evita pérdida pero bloquea correcciones; prioridad por origen/calidad permite mejora pero necesita reglas deterministas y preservar procedencia. Definir empate y corrección de datos erróneos. |
| `queued` ausente frente a `false`, y asociación ausente/cerrada para backlog. | Valor triestado y cuarentena hasta resolver (no atribuye mal, retrasa disponibilidad) o aceptar parcialmente sin exposición (conserva evidencia, requiere ruta/reglas). Nunca inventar relación. |
| Colisión real/reutilización de `seq`: el checkpoint de persistencia sigue pendiente. | Rechazar/cuarentenar nueva recepción (protege histórico, exige operación manual) o versionar identidad con nueva clave (más cobertura, rompe convergencia/consultas). Definir huella, evidencia, aviso y relación con cancelaciones antes de implementar. |
| Validación exacta de tipos, severidades, rangos, tamaños, desconocidos y `cancels_seq`. | Rechazo estricto (seguridad, riesgo de perder diagnóstico) o retención separada de desconocidos/corruptos (observabilidad, nueva ruta y permisos). `device_contract.md` exige conservar tipos desconocidos para diagnóstico, nunca promoverlos a emergencia. |
| Cancelación concurrente/duplicada y atomicidad entre fila `cancel`, original, entregas y futuras notificaciones. | Transacción o actualización multipath con condiciones (coherencia más fuerte, implementación compleja) frente a reconciliación idempotente asíncrona (más simple, ventana inconsistente). Definir prioridad y manejo de conflictos. |
| `receivedAt` de un placeholder creado por `cancel` antes del original. | Registrar la primera recepción del `cancel` como hora del placeholder (refleja evidencia más temprana, no hora del original) o reservar `receivedAt` para la primera recepción del original y guardar la del cancel aparte (semántica más precisa, requiere otro campo). Afecta orden y conciliación. |
| Autenticación del origen MQTT: el bridge ve topic/payload, pero no demuestra por sí mismo que el cliente tenga identidad única por SDA. | Verificar ACL de publicación por dispositivo en el broker (fuerte identidad, requiere configuración/ensayo externo) o reconocer credencial compartida y aplicar allowlist/asociación en backend (reduce suplantación accidental, no prueba origen físico). No declarar “topic autenticado” sin evidencia. |
| Ground Control HTTP/JWT, MOMSN rollover y conversión binaria completa. | No elegir todavía: obtener especificación oficial del proveedor. Cualquier supuesto alternativo arriesga aceptar origen falso o duplicar entregas; el webhook queda fuera de este bloque. |

Estas decisiones no son recomendaciones convertidas en requisitos. Una implementación puede avanzar solo en ramas independientes que no dependan de la decisión pendiente; no marcar aceptación completa mientras falten políticas de escritura necesarias.

## Matriz de aceptación propuesta

Cada prueba debe usar datos ficticios y dobles/Emulator. La columna “estado final” describe el **objetivo**, no una afirmación de que ya pasa hoy. Donde la política siga abierta, la prueba se concreta **después** de resolverla; se indica el invariante verificable ahora.

| Escenario / entrada | Comportamiento esperado | Estado final | Prueba automatizable propuesta |
|---|---|---|---|
| Evento MQTT nuevo válido `deviceId,seq` asociado | Validar topic/payload/asociación y persistir una vez | Una clave nominal, `receivedAt` inicial, sin ack global nuevo | Writer/Emulator con reloj controlado y asociación ficticia |
| Mismo evento duplicado idéntico | No crear otro incidente ni notificación; no borrar campos | Misma clave, `receivedAt` intacto | Entregar dos veces y comparar snapshot |
| Retransmisión con `ts` diferente o ausente | Tratar como misma identidad; preservar cancelación y primera recepción; conflicto de `ts` según decisión | Una clave, sin retroceso de estado | Repetir evento con reloj distinto; probar política elegida |
| Mismo `(deviceId,seq)` por Iridium y MQTT, en ambos órdenes | Convergencia y enriquecimiento sin segunda notificación | Un incidente con procedencia de ambos, datos compatibles | Entradas sintéticas de dos transportes; sin satélite real; completar al existir webhook |
| `cancel` posterior con `cancels_seq` | Aplicar evidencia al original sin tocar estado personal | Original cancelado, fila `cancel` histórica conservada | Writer con incidente→cancel; prueba existente y extensión canónica |
| `cancel` anterior al original | Conservar placeholder/evidencia y fusionar después | Una clave de original cancelado, no reactivado | Writer con cancel→incidente; prueba existente y extensión canónica |
| Histórico sin `vehicleId` y `userId` autorizado | Mantener lectura compatible; no fabricar asociación retroactiva | Histórico legible para propietario, sin reescritura | Fixture Flutter de consulta dual y reglas Emulator |
| Nuevo evento sin asociación | No atribuir a otro vehículo ni exponer/notificar como autorizado | Según política abierta: cuarentena o persistencia no expuesta | Simular resolución nula; verificar invariante y luego política |
| JSON/payload inválido o `id` distinto del topic | Error controlado, sin incidente ni aviso | RTDB canónica intacta | Tabla de casos para parser/validador con identidad ficticia |
| `seq` repetido con contenido incompatible | No sobrescribir silenciosamente el incidente previo | Registro previo y cancelación intactos; rechazo/cuarentena según política | Dos payloads de misma clave, tipos/huella incompatibles |
| Primera recepción seguida de reintento | Preservar `receivedAt` original; `updatedAt` según cambio válido | Primera hora estable, última incorporación distinguible | Reloj inyectado, comparar campos antes/después |
| Actualización parcial posterior | Completar datos válidos sin `null` destructivo | Métricas/ubicación previa y cancelación/ack intactos | Writer con aportes parciales y estado preexistente |
| `queued: true`, sin GNSS ni `ts` válido | Mantener identidad y marca de retraso; no inventar tiempo/posición | Incidente parcial, orden con tiempo backend y calidad explícita | Fixture MQTT retrasado con reloj controlado |
| Evento MQTT histórico existente | Flutter sigue leyendo `ts` cadena/numérico/ausente y fallback de ack/`receivedAt` | Datos existentes sin migración destructiva ni duplicados | Pruebas de modelo/repositorio y Emulator con fixtures históricos |

## Criterio de cierre del Bloque 2.1

No basta con crear este documento. Cerrar solo cuando las decisiones bloqueantes estén resueltas y versionadas, la implementación local compatible exista, pasen pruebas de validación/idempotencia/orden/cancelación y se documente qué casos de la matriz quedaron diferidos al webhook, FCM o hardware. La publicación en Firebase real y cualquier prueba física requieren autorización separada conforme a `AGENTS.md`.
