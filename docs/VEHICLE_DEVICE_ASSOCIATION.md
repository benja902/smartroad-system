# Asociación conceptual propietario–vehículo–dispositivo

## Propósito

Este documento define la relación conceptual entre propietarios, vehículos y dispositivos SDA durante el MVP. No diseña nodos RTDB, claves de almacenamiento, reglas Firebase, pantallas, endpoints ni código.

## Principio de propiedad

La propiedad se establece sobre el vehículo, no directamente sobre el SDA. El dispositivo es hardware asociado administrativamente al vehículo durante un periodo determinado.

Reemplazar un SDA no cambia la identidad del vehículo ni las relaciones de su propietario y contactos autorizados.

## Cardinalidades

- Un usuario puede ser propietario de cero o varios vehículos.
- Un vehículo puede tener cero o un propietario activo; durante el MVP nunca puede tener más de uno.
- Un vehículo puede tener cero o un SDA activo; durante el MVP nunca puede tener más de uno.
- Un SDA puede estar asociado activamente con cero o un vehículo.
- Un vehículo puede acumular asociaciones históricas con distintos SDA.
- Un SDA puede acumular asociaciones históricas, siempre que sus periodos activos no se solapen.
- Los contactos autorizados se relacionan con el vehículo y no directamente con el SDA.
- Cada incidente conserva el vehículo relacionado y el `deviceId` que realmente lo originó.

## Ciclo de vida de la asociación vehículo–SDA

1. El SDA se incorpora mediante un proceso administrativo de provisión.
2. Se prepara su asociación con un vehículo.
3. Se comprueba que el vehículo y el SDA no tengan otra asociación activa incompatible.
4. Un proceso administrativo activa la asociación.
5. Flutter puede consultar la asociación y la información operativa permitida.
6. La asociación puede cerrarse por reemplazo, retiro, reasignación o corrección administrativa.
7. La asociación cerrada no se elimina como consecuencia del reemplazo y se conserva para auditoría según una política de retención que se definirá posteriormente.

## Estados conceptuales

### `pending`

Asociación preparada administrativamente, pero todavía no vigente. No convierte al SDA en fuente activa del vehículo.

### `active`

Asociación vigente y autorizada. El SDA es el dispositivo operativo actual del vehículo.

### `ended`

Asociación que estuvo activa y fue cerrada por reemplazo, retiro, reasignación o corrección. Se mantiene como antecedente para auditoría y para resolver la procedencia de incidentes.

El estado `ended` no vuelve automáticamente inválido un evento recibido con posterioridad. Un evento `queued` o retrasado puede haberse originado mientras la asociación todavía estaba activa.

### `cancelled`

Asociación preparada que se descartó antes de llegar a estar activa. No forma parte del historial operativo del SDA, aunque puede conservarse como antecedente administrativo según la política de retención futura.

## Procedimiento conceptual de reemplazo

1. Identificar el vehículo sin alterar su identidad.
2. Validar administrativamente el nuevo `deviceId`.
3. Confirmar que el nuevo SDA no tenga otra asociación activa.
4. Cerrar la asociación anterior sin eliminarla como consecuencia del reemplazo.
5. Activar la nueva asociación sin solapamiento entre periodos activos.
6. Mantener intactas las relaciones del propietario y de los contactos autorizados.
7. Mantener intactos los incidentes históricos y el `deviceId` que los originó.
8. Hacer que las consultas operativas posteriores identifiquen al nuevo SDA como dispositivo activo.

La provisión, asociación, reasociación, reemplazo y retiro son operaciones del backend o de un proceso administrativo autorizado. No son permisos normales del propietario desde Flutter.

## Eventos recibidos después del cierre

La recepción de un evento después de que una asociación pasó a `ended` no determina por sí sola que el evento sea inválido:

- nunca se atribuye silenciosamente al SDA actualmente activo;
- no se descarta únicamente porque el SDA de origen tenga una asociación cerrada;
- conserva el `deviceId` que lo originó;
- utiliza el historial de asociaciones para resolver su posible procedencia;
- puede corresponder a un evento `queued` o retrasado, originado cuando la asociación todavía estaba activa.

La política exacta para evaluar el tiempo del evento, el tiempo de recepción, el indicador `queued` y la confiabilidad de los timestamps se definirá en la Fase 2. Hasta entonces, este modelo no presume validez ni invalidez automática para esos eventos.

## Invariantes

- La propiedad siempre recae sobre el vehículo, no sobre el SDA.
- Un vehículo nunca tiene más de un propietario activo.
- Un vehículo nunca tiene más de un SDA activo.
- Un SDA nunca está activo en dos vehículos al mismo tiempo.
- Los periodos activos de asociaciones de un mismo vehículo o SDA no se solapan.
- Reemplazar el hardware no cambia el `vehicleId`.
- Reemplazar el hardware no modifica al propietario ni a los contactos autorizados.
- Ningún incidente histórico cambia el `deviceId` que lo originó.
- Una asociación no se elimina como consecuencia de reemplazar el SDA; se conserva para auditoría según la política de retención futura.
- Una asociación `ended` no invalida automáticamente eventos recibidos posteriormente.
- Un evento de un SDA anterior nunca se reasigna silenciosamente al SDA activo actual.
- Conocer un `deviceId` no permite asociarlo ni concede acceso.
- El propietario solo consulta la asociación y la información operativa autorizada del SDA.
- Las operaciones administrativas sensibles no se exponen como permisos normales del propietario.

## Efecto de un reemplazo

### Propietario

Conserva su relación con el vehículo. Puede consultar el nuevo SDA activo y su información operativa permitida, pero no ejecuta la provisión ni el reemplazo.

### Contactos autorizados

Conservan sus autorizaciones porque están relacionados con el vehículo. El reemplazo del hardware no crea ni elimina sus relaciones.

### Incidentes existentes

Permanecen vinculados al vehículo y conservan el `deviceId` real que los originó. No se reescriben para apuntar al nuevo SDA.

### Incidentes nuevos

Los eventos originados por el SDA activo conservan su propio `deviceId`. Los eventos retrasados de un SDA anterior se evalúan contra el historial de asociaciones y la futura política temporal de la Fase 2; no se descartan ni reasignan automáticamente.

### Historial de asociaciones

Permite distinguir qué SDA estuvo asociado con el vehículo en cada periodo. No se elimina como consecuencia del reemplazo y se conserva para auditoría conforme a una política de retención que se definirá posteriormente.

## Decisiones diferidas

Se definirán en tareas posteriores:

- estructura final de nodos y campos RTDB;
- claves de almacenamiento;
- reglas Firebase;
- política de retención;
- política temporal para eventos retrasados o `queued`;
- confiabilidad y precedencia de timestamps;
- pantallas, endpoints e implementación.
