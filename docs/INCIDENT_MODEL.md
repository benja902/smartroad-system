# Modelo mínimo de incidente

## Propósito

Este documento define la representación conceptual mínima de un incidente para el MVP de SmartRoad. Cada dato o estado incluido tiene un productor y un consumidor actual entre firmware, bridge, Firebase, Flutter y FCM.

No define nodos RTDB, claves físicas de almacenamiento, reglas Firebase, código Node/Flutter, endpoints, pantallas ni implementación FCM.

## Qué constituye un incidente

Un incidente representa un evento de seguridad del vehículo:

- `crash`;
- `rollover`;
- `sos`.

La severidad determina, junto con el tipo, si el incidente es crítico y qué usuarios pueden ser destinatarios.

No constituyen incidentes independientes:

- `cancel`: modifica el incidente referenciado;
- `power_loss`, `low_battery` y `booted`: eventos técnicos;
- diagnóstico: información técnica;
- posición y disponibilidad: telemetría o estado;
- `test`: evento de prueba, salvo que una prueba controlada lo procese explícitamente fuera del flujo real;
- tipos desconocidos: se conservan para diagnóstico, pero no se promueven automáticamente a incidentes.

## Identidad conceptual

La identidad canónica nominal del incidente es `(deviceId, seq)`.

- `deviceId` es producido por el firmware SDA y representa la identidad lógica del dispositivo.
- RockBLOCK y su IMEI no producen ni reemplazan el `deviceId`. Permiten resolver y validar que una entrega satelital corresponde a un `deviceId` ya aprovisionado.
- `seq` es producido por la máquina de eventos del firmware SDA.
- MQTT e Iridium son transportes del mismo incidente, no incidentes diferentes.
- La identidad nominal permite converger recepciones sin asumir todavía unicidad absoluta ante reinicios o reutilización inesperada de `seq`.
- La política defensiva frente a colisiones se define en la Fase 2.

Cada incidente conserva el `deviceId` que realmente lo originó. Reemplazar el SDA no reescribe la procedencia de incidentes existentes.

## Resolución del vehículo

Para el MVP, el bridge resuelve primero `vehicleId` mediante la asociación activa `deviceId → vehicleId`.

- Esta es la ruta normal para el único prototipo SDA.
- El `vehicleId` resuelto delimita lecturas autorizadas y destinatarios.
- Un evento nunca se atribuye silenciosamente al SDA activo de otro vehículo.
- Si no existe una asociación activa compatible, el evento no se expone ni se notifica como si estuviera correctamente asociado.
- La resolución automatizada mediante asociaciones históricas queda como capacidad futura o respaldo para eventos retrasados de un SDA retirado.
- Hasta implementar ese respaldo, un evento anómalo conserva su `deviceId` y requiere tratamiento controlado; no se descarta ni reasigna silenciosamente.

## Datos mínimos del MVP y consumidores

| Dato conceptual | Productor u origen | Consumidores actuales | Justificación MVP |
|---|---|---|---|
| `deviceId` | Firmware SDA | Bridge, Firebase y Flutter propietario | Identifica el SDA de origen y participa en deduplicación |
| `seq` | Firmware SDA | Bridge y Firebase; Flutter lo usa indirectamente mediante la referencia del incidente | Completa la identidad nominal y permite correlacionar cancelaciones |
| `vehicleId` | Bridge, resuelto desde la asociación activa del `deviceId` | Firebase, Flutter y resolución de destinatarios FCM | Delimita propiedad, autorización y contexto vehicular |
| Tipo | Firmware SDA | Bridge, Firebase, Flutter y FCM | Separa incidentes, cancelaciones y eventos no notificables |
| Severidad | Firmware SDA | Bridge, Firebase, Flutter y FCM | Determina presentación y elegibilidad crítica |
| Tiempo reportado | Firmware SDA, cuando dispone de hora válida | Bridge, Firebase y Flutter | Informa cuándo declaró el SDA que ocurrió el evento |
| Tiempo de recepción | Bridge o webhook | Firebase y Flutter | Permite ordenar y explicar eventos retrasados cuando falta una hora confiable |
| Tiempo de última actualización | Bridge o webhook | Firebase y Flutter | Permite reflejar enriquecimientos posteriores |
| `queued` | Firmware SDA | Bridge, Firebase y Flutter | Indica que la entrega fue diferida |
| Procedencia de transporte | Bridge MQTT o webhook Iridium | Bridge y Firebase | Permite deduplicar, converger y diagnosticar enriquecimientos |
| Estado global | Bridge a partir de eventos SDA válidos | Firebase, Flutter y política FCM | Distingue un incidente activo de uno cancelado |
| Ubicación disponible | Firmware SDA o Ground Control | Bridge, Firebase y Flutter | Permite atender y representar el incidente |
| Origen y calidad de ubicación | Firmware SDA o webhook Ground Control | Bridge, Firebase y Flutter | Evita confundir GNSS con una estimación CEP |
| Evidencia de cancelación | Firmware SDA mediante `cancel` | Bridge, Firebase y Flutter | Conserva la evolución global del mismo incidente |

Los datos ausentes permanecen opcionales. El MVP no introduce un estado adicional `partial` o `enriched`: la parcialidad se representa mediante campos opcionales y aportes de transporte.

## Datos técnicos opcionales

El incidente puede incorporar las métricas técnicas que el firmware ya publica, como aceleración, delta-V, inclinación o información operativa disponible.

Sus consumidores actuales son:

- bridge, para validar y normalizar;
- Firebase, para conservar la información permitida;
- Flutter propietario, para mostrar el detalle técnico autorizado.

Estas métricas no se exponen al contacto autorizado y no son necesarias para decidir la identidad del incidente. Cualquier métrica sin consumidor actual queda fuera del modelo mínimo.

## Tiempos

El modelo distingue:

- **tiempo reportado:** declarado por el SDA y opcional;
- **tiempo de recepción:** registrado por el backend para cada recepción;
- **tiempo de última actualización:** registrado cuando se incorpora información válida.

La política exacta para timestamps ausentes, inválidos o iguales a cero, así como su relación con `queued`, se define en la Fase 2.

## Transportes y enriquecimiento

- MQTT e Iridium aportan datos al mismo incidente nominal.
- Una recepción Iridium puede crear la representación con menos datos.
- Una recepción MQTT posterior puede completar los campos ausentes.
- Una retransmisión no crea automáticamente un incidente nuevo.
- `(imei, momsn)` deduplica la entrega satelital, pero no identifica el incidente.
- El enriquecimiento es idempotente y no puede borrar una cancelación ni estados individuales.
- No se conserva un estado genérico de completitud sin consumidor actual.

## Ubicación y calidad

La ubicación puede faltar y puede incorporarse posteriormente.

- GNSS procede del SDA.
- CEP procede de Iridium/Ground Control y es una estimación diferente.
- Deben conservarse conceptualmente origen, validez, antigüedad y calidad disponibles.
- Flutter debe distinguir una posición GNSS de una estimación CEP.
- La política para elegir entre varias observaciones se define en la Fase 2.

## Estado global del incidente

El MVP utiliza únicamente:

- `active`: incidente sin una cancelación SDA aplicada;
- `cancelled`: incidente cancelado por el evento SDA correspondiente.

No se introduce todavía un flujo global de resolución por operador. Leer, abrir o reconocer personalmente un incidente no modifica su estado global.

## Estado individual por usuario

El estado individual se mantiene separado del incidente global. Para el MVP incluye únicamente información consumida por Flutter, Firebase o FCM:

- lectura del incidente por el usuario;
- decisión o registro de envío de notificación por destinatario.

Abrir el detalle puede marcar el incidente como leído. No se añade un estado separado de apertura sin otro consumidor.

El estado individual:

- no cancela el incidente;
- no modifica el estado de otros usuarios;
- no concede autorización adicional;
- permanece asociado al usuario correspondiente.

Estados personales adicionales o trazabilidad exhaustiva de vistas quedan como evolución futura.

## Resolución conceptual de destinatarios

La resolución separa tres decisiones:

1. **Elegibilidad histórica:** relación usuario–vehículo vigente cuando ocurrió el incidente.
2. **Autorización actual:** relación vigente cuando el usuario intenta acceder.
3. **Decisión FCM:** determinación posterior de si corresponde enviar una notificación.

Para el MVP:

- el propietario autorizado puede acceder a los incidentes de su vehículo;
- un contacto solo es elegible para incidentes críticos autorizados;
- una persona revocada no recupera acceso por haber sido elegible históricamente;
- conocer identificadores no concede acceso;
- los destinatarios SMS configurados en el SDA no forman parte de la resolución SmartRoad.

La ruta normal usa la asociación activa del vehículo. La evaluación automatizada de relaciones históricas complejas queda como evolución futura o respaldo.

## Cancelación

Un evento `cancel`:

- conserva su propio `seq`;
- referencia mediante `cancels_seq` el evento original;
- no crea un incidente independiente;
- cambia a `cancelled` el estado global del incidente referenciado;
- conserva su procedencia y tiempo de recepción;
- puede llegar antes o después del evento original.

Si llega primero, el bridge debe conservar la evidencia necesaria para reconciliarla posteriormente. Un enriquecimiento posterior nunca revierte la cancelación.

## Incidentes retrasados o `queued`

- `queued` describe una entrega diferida, no un incidente diferente.
- La ausencia de ubicación o tiempo reportado no invalida automáticamente un incidente.
- Una asociación vehículo–SDA cerrada no invalida automáticamente un evento recibido posteriormente.
- Un evento de un SDA retirado nunca se atribuye silenciosamente al SDA actual.
- Para el flujo normal del MVP se usa la asociación activa `deviceId → vehicleId`.
- La resolución histórica automatizada y la política temporal defensiva se completarán en la Fase 2 o como respaldo futuro.

## Invariantes de seguridad e idempotencia

- Solo los eventos de seguridad definidos crean incidentes.
- MQTT e Iridium convergen sin crear incidentes distintos.
- `deviceId` siempre procede del firmware SDA; IMEI solo valida y resuelve el transporte satelital.
- La deduplicación no confía ciegamente en `seq` hasta cerrar la política defensiva.
- El `deviceId` histórico nunca se reescribe por reemplazar hardware.
- Una actualización no revierte cancelaciones ni estados individuales.
- Los contactos no reciben datos técnicos restringidos.
- La elegibilidad histórica no sustituye la autorización actual.
- Una revocación impide accesos posteriores.
- SmartRoad, FCM y destinatarios SMS son mecanismos separados.
- Ningún campo, estado o relación sin consumidor actual se incorpora al modelo mínimo.

## Evolución futura

Quedan fuera de esta representación mínima:

- resolución histórica automatizada para todos los periodos de asociación;
- estado global de resolución por operador;
- estados explícitos de completitud;
- reconocimientos personales avanzados;
- historial exhaustivo de transiciones y vistas;
- políticas generales para nuevos transportes o flotas;
- campos sin consumidor actual en firmware, bridge, Firebase, Flutter o FCM.
