# Modelo mínimo de Firebase Realtime Database

## Propósito

Este documento define la estructura conceptual mínima de RTDB para el MVP de SmartRoad con un único SDA físico. No implementa reglas Firebase, migraciones, código Flutter, bridge, datos reales ni cambios en Firebase.

El diseño preserva y evoluciona incrementalmente el flujo existente:

`MQTT → bridge Node.js → RTDB → Flutter`

Se mantienen como base los nodos actuales `users`, `vehicles`, `devices` y `events`. Solo se añaden las relaciones y proyecciones indispensables para autorización básica, contactos, RockBLOCK e idempotencia.

## Estructura conceptual

```text
users/{uid}
vehicles/{vehicleId}
vehicleContacts/{vehicleId}/{contactUid}
devices/{deviceId}
deviceRegistry/{deviceId}
events/{eventKey}
userIncidentState/{uid}/{eventKey}
contactIncidents/{vehicleId}/{publicIncidentId}
satelliteDeliveries/{deliveryKey}
```

Los nombres representan responsabilidades conceptuales. Las reglas, índices y operaciones concretas se definirán en tareas posteriores.

## 1. Usuarios

### Ruta

`users/{uid}`

### Clave

`uid` es el identificador emitido por Firebase Authentication.

### Contenido mínimo

| Campo | Uso MVP |
|---|---|
| `name` | Nombre mostrado por Flutter; conserva el campo consumido actualmente |
| `phone` | Dato de contacto de la aplicación, cuando sea necesario |
| `vehicleIds/{vehicleId}` | Índice ligero de vehículos actualmente accesibles para el usuario |

Firebase Authentication sigue siendo la autoridad de identidad. No se define un rol global en `users`.

`vehicleIds` permite conservar el acceso actual de Flutter sin buscar todas las relaciones de la base. Debe mantenerse de forma coherente con el propietario o contacto activo mediante una operación controlada por el backend.

No se incluyen preferencias avanzadas, organizaciones ni perfiles comerciales.

## 2. Vehículo

### Ruta

`vehicles/{vehicleId}`

### Contenido mínimo

| Campo | Uso MVP |
|---|---|
| `ownerId` | `uid` del único propietario activo |
| `deviceId` | SDA activo asociado con el vehículo |
| `brand` | Información básica consumida por Flutter |
| `model` | Información básica consumida por Flutter |
| `plate` | Información básica consumida por Flutter |
| `label` | Etiqueta visible opcional |

Se conservan los nombres `ownerId` y `deviceId` ya utilizados por el flujo actual. Para el MVP:

- existe como máximo un propietario activo;
- existe como máximo un SDA activo;
- no se modelan flotas ni múltiples propietarios;
- sustituir `deviceId` no modifica `vehicleId`, propietario o contactos.

## 3. Dispositivo SDA

### Ruta operativa

`devices/{deviceId}`

### Clave

`deviceId` es producido por el firmware SDA. No lo genera RockBLOCK ni el IMEI.

### Contenido operativo mínimo

| Campo o bloque | Uso MVP |
|---|---|
| `online` y `lastSeen` | Disponibilidad MQTT consumida por Flutter propietario |
| `state` | Estado operativo más reciente |
| `gnss` | Posición o estado GNSS más reciente |
| `power` | Batería y alimentación |
| `sensors`, `modem`, `sd`, `system` | Estado técnico ya emitido y consumido por el flujo existente |

El bridge actualiza en esta ruta únicamente el estado operativo proveniente del SDA.

### Registro administrativo mínimo

`deviceRegistry/{deviceId}`

| Campo | Uso MVP |
|---|---|
| `vehicleId` | Asociación administrativa con el vehículo activo |
| `rockblockImei` | Relación opcional con el módulo satelital; dato protegido, no secreto |
| `active` | Indica si el dispositivo está provisionado como activo |

Esta ruta queda reservada al backend y al proceso administrativo. Separarla de `devices` evita que la lectura operativa del propietario exponga el IMEI o permita confundir telemetría con provisión.

No se almacenan credenciales MQTT, secretos de Ground Control ni claves privadas.

Para el MVP, la resolución principal es `deviceId → vehicleId` mediante la asociación activa. La resolución histórica automatizada queda como respaldo o evolución futura.

## 4. Contactos autorizados

### Ruta

`vehicleContacts/{vehicleId}/{contactUid}`

### Contenido mínimo

| Campo | Uso MVP |
|---|---|
| `status` | `pending`, `active` o `revoked` |
| `activeFrom` | Inicio de vigencia cuando la autorización se activa |
| `revokedAt` | Fin de vigencia cuando se revoca |

Para este MVP se admiten como máximo tres contactos SmartRoad `pending` o `active` por vehículo. Las relaciones `revoked` permanecen para historial y no ocupan cupo. Esta decisión funcional es independiente de los destinatarios SMS del SDA.

Esta relación:

- vincula al usuario con el vehículo, no con el SDA;
- permite al backend y a las futuras reglas determinar si el contacto está activo;
- permite evaluar si la relación estaba vigente cuando ocurrió un incidente;
- no concede acceso a datos técnicos del SDA;
- no modifica destinatarios SMS configurados en el firmware.

Cuando una relación pasa a `active`, el backend puede añadir `vehicleIds/{vehicleId}` al usuario. Al revocarla, debe retirar ese acceso actual sin borrar la relación conceptual necesaria para determinar el periodo previo.

No se incluyen expiraciones configurables, niveles de permiso ni mecanismos complejos de invitación.

## 5. Incidentes y eventos

### Ruta existente

`events/{eventKey}`

Se conserva `events` para no reemplazar el flujo funcional actual. Los incidentes de seguridad son el subconjunto con tipo `crash`, `rollover` o `sos`. Los eventos técnicos pueden permanecer en esta colección para el propietario, pero no se proyectan a contactos.

### Clave nominal

`eventKey = {deviceId}_{seq}`

Esta clave preserva la idempotencia actual y representa nominalmente `(deviceId, seq)`. La política defensiva ante reutilización inesperada de `seq` se definirá en la Fase 2 y no debe provocar sobrescrituras silenciosas.

### Contenido mínimo

| Campo o bloque | Uso MVP |
|---|---|
| `id` | `deviceId` de origen, conservando el nombre del contrato MQTT actual |
| `seq` | Secuencia emitida por el firmware |
| `vehicleId` | Vehículo resuelto desde la asociación activa |
| `userId` | Compatibilidad temporal con la consulta actual del propietario; no es fuente de autorización |
| `type` | Clasificación del mensaje |
| `severity` | Severidad recibida |
| `status` | `active` o `cancelled` para incidentes |
| `ts` | Tiempo reportado por el SDA, opcional; durante la transición puede ser cadena ISO 8601 o timestamp numérico |
| `receivedAt` | Primera recepción del backend |
| `updatedAt` | Última incorporación válida |
| `queued` | Entrega diferida indicada por el firmware |
| `transports` | Marcas y tiempos de recepción por MQTT e Iridium |
| `position` | Ubicación disponible, con origen y calidad |
| `detection` y `device` | Datos técnicos permitidos para el propietario |
| `cancelledBySeq` y `cancelledAt` | Evidencia de cancelación aplicada |

`userId` puede mantenerse durante la transición porque el repositorio Flutter actual lo consume. El objetivo incremental es que las lecturas autorizadas dependan de `vehicleId` y de las relaciones del usuario, no de este campo de compatibilidad.

La lectura y escritura transitoria de estos campos se detalla en `RTDB_COMPATIBILITY_MVP.md`. La compatibilidad de lectura no autoriza a reescribir automáticamente los eventos históricos.

### Estado individual mínimo

`userIncidentState/{uid}/{eventKey}`

| Campo | Uso MVP |
|---|---|
| `acknowledged` | Indica que ese usuario reconoció personalmente el incidente en Flutter |

Este estado no modifica `status`, la cancelación global ni el estado de otros usuarios. No se incluyen todavía preferencias, analítica de lectura ni estados de entrega FCM.

### Convergencia de transportes

- MQTT primero e Iridium después actualizan el mismo `eventKey`.
- Iridium primero y MQTT después también actualizan el mismo `eventKey`.
- Cada transporte completa únicamente información válida y no borra datos previos.
- Una actualización no revierte `cancelled`.
- La ausencia de ubicación, tiempo reportado o métricas no impide una representación parcial.

### Proyección segura para contactos

`contactIncidents/{vehicleId}/{publicIncidentId}`

Esta proyección contiene únicamente incidentes críticos autorizados y evita exponer datos técnicos o el `deviceId` mediante el contenido o la clave visible.

Contenido mínimo:

| Campo o bloque | Uso MVP |
|---|---|
| `eventRef` | Referencia interna opaca al incidente canónico |
| `type` y `severity` | Contexto crítico |
| `status` | Estado global del incidente |
| `ts` y `receivedAt` | Tiempos necesarios para presentación |
| `position` | Ubicación permitida con origen y calidad |
| `vehicleLabel` | Identificación básica del vehículo |

`publicIncidentId` es una referencia opaca generada por el backend para Flutter y FCM. No sustituye la identidad canónica `(deviceId, seq)`.

Solo el backend crea o actualiza esta proyección. Los eventos técnicos y los incidentes no críticos no aparecen aquí.

## 6. Idempotencia

### MQTT

El bridge valida el payload y resuelve `deviceId → vehicleId` antes de escribir. La clave determinista `events/{deviceId}_{seq}` concentra las retransmisiones nominales del mismo evento.

Las actualizaciones deben fusionar campos y no reemplazar el nodo completo. La política ante una colisión real de `seq` pertenece a la Fase 2.

### Iridium

`satelliteDeliveries/{deliveryKey}`

`deliveryKey` representa de forma determinista `(imei, momsn)` y es accesible únicamente para backend administrativo.

Contenido mínimo:

| Campo | Uso MVP |
|---|---|
| `eventKey` | Incidente nominal al que convergió la entrega |
| `receivedAt` | Primera recepción del webhook |

El webhook debe registrar la entrega una sola vez y después fusionar su contenido con `events/{eventKey}`. No se almacenan secretos en esta ruta.

### Cancelación

Un evento `cancel` no crea un incidente visible independiente. El bridge usa `cancels_seq` para actualizar el nodo nominal del incidente original:

`events/{deviceId}_{cancelsSeq}`

Si la cancelación llega primero, puede crear una representación mínima con estado `cancelled` y evidencia de cancelación. El evento original posterior completa ese mismo nodo sin revertir el estado.

Los registros `cancel` independientes existentes se conservan durante la transición para no perder evidencia. No deben mostrarse como incidentes independientes ni eliminarse antes de validar la reconciliación canónica.

Las escrituras coordinadas sobre índices, incidente y proyección deben diseñarse como actualizaciones multipath o transacciones en la implementación posterior.

## 7. Lecturas autorizadas

Las siguientes rutas describen el alcance conceptual. Las reglas Firebase se escribirán en una tarea posterior.

### Propietario

Puede consultar:

- `users/{uid}` para su información mínima;
- `vehicles/{vehicleId}` cuando sea su propietario activo;
- `devices/{deviceId}` para el SDA activo de su vehículo;
- `events` filtrado y acotado por `vehicleId`;
- `vehicleContacts/{vehicleId}` para gestionar contactos del vehículo.

Puede ver incidentes, eventos técnicos y datos operativos permitidos. No puede provisionar o reasociar `deviceId`, IMEI ni modificar identidad o configuración crítica.

### Contacto autorizado

Puede consultar:

- su propia información mínima;
- su propia relación en `vehicleContacts/{vehicleId}/{uid}`;
- `contactIncidents/{vehicleId}` únicamente mientras la relación esté activa.

No consulta directamente:

- `devices`;
- `events`;
- datos técnicos;
- IMEI o `deviceId`;
- otros contactos;
- configuración del vehículo o SDA.

### Backend

El bridge, webhook y procesos administrativos son los únicos escritores de asociaciones, estado del dispositivo, eventos canónicos, entregas satelitales y proyecciones para contactos.

Flutter no escribe en `events`, `devices`, `satelliteDeliveries` ni en campos administrativos. Solo podrá escribir su propio `userIncidentState/{uid}/{eventKey}` cuando las reglas correspondientes hayan sido implementadas y probadas.

## Consistencia mínima

Las siguientes operaciones requieren actualización coherente de sus rutas relacionadas:

- activar propietario o contacto y actualizar `users/{uid}/vehicleIds`;
- asociar SDA y actualizar `vehicles/{vehicleId}/deviceId` y `deviceRegistry/{deviceId}/vehicleId`;
- registrar el IMEI en `deviceRegistry/{deviceId}`;
- aceptar un incidente y crear o actualizar su proyección crítica;
- revocar un contacto y retirar su acceso actual;
- cancelar un incidente y reflejar el estado sin crear otro incidente.

La implementación deberá usar operaciones atómicas de RTDB cuando varias rutas formen una sola decisión.

## Evolución futura

Quedan fuera del modelo MVP:

- multiempresa y múltiples flotas;
- varios propietarios por vehículo;
- historial completo y automatizado de asociaciones;
- expiraciones y niveles avanzados para contactos;
- dashboards y analítica;
- auditoría avanzada y políticas definitivas de retención;
- migraciones generales;
- paginación sofisticada;
- proyecciones para nuevos roles o transportes;
- esquemas administrativos masivos.
