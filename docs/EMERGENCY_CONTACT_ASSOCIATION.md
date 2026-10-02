# Asociación conceptual de contactos autorizados

## Propósito

Este documento define la relación conceptual entre un usuario, un vehículo y su autorización como contacto de emergencia en SmartRoad. No diseña nodos RTDB, reglas Firebase, pantallas, mecanismos de invitación ni código.

Los contactos autorizados de SmartRoad son independientes de los destinatarios SMS configurados en el SDA.

## Cardinalidades usuario–vehículo

- Un vehículo puede tener cero, uno o varios contactos autorizados.
- Un usuario puede ser contacto autorizado de cero o varios vehículos.
- Un mismo usuario puede ser propietario de un vehículo y contacto autorizado de otros.
- Cada autorización corresponde a un usuario y un vehículo concretos.
- La autorización se relaciona con el vehículo, no directamente con el SDA.
- Reemplazar el SDA no modifica las autorizaciones del vehículo.

## Estados conceptuales de la autorización

### `pending`

Incorporación o invitación propuesta, todavía sin acceso. Puede ser iniciada por el propietario activo del vehículo o por un proceso administrativo autorizado.

### `active`

Autorización vigente. El usuario puede acceder al alcance crítico permitido para ese vehículo.

### `declined`

Propuesta rechazada antes de llegar a estar activa.

### `revoked`

Autorización retirada explícitamente. El usuario pierde inmediatamente el acceso futuro.

### `expired`

Autorización cuyo periodo de vigencia terminó.

### `cancelled`

Propuesta anulada antes de ser aceptada o activada.

## Ciclo de vida

1. El propietario activo del vehículo puede iniciar la incorporación o invitación de un contacto autorizado. Un proceso administrativo también puede iniciarla o intervenir cuando corresponda.
2. El backend valida que quien inicia la operación tenga autoridad sobre el vehículo y persiste de forma segura la propuesta y sus cambios de estado.
3. La propuesta permanece en `pending` y no concede acceso.
4. La aceptación o activación confirmada inicia el periodo de vigencia y cambia la relación a `active`.
5. El contacto accede únicamente al alcance autorizado mientras la relación permanezca activa.
6. La autorización puede terminar por revocación, expiración o cierre administrativo.
7. La relación finalizada no se elimina como consecuencia de su cierre y se conserva para auditoría según una política de retención que se definirá posteriormente.
8. Una autorización posterior crea un nuevo periodo; no reactiva ni reescribe el anterior.

El mecanismo concreto de invitación, su interfaz, enlaces, códigos y forma de aceptación se definirán posteriormente.

## Inicio y fin de vigencia

- Una propuesta `pending` no concede acceso.
- La vigencia comienza cuando la aceptación o activación queda confirmada.
- La vigencia termina en el momento efectivo de revocación o expiración.
- Una revocación elimina inmediatamente todo acceso posterior, incluso a incidentes que antes fueran visibles.
- Conservar el historial de la relación no conserva el permiso de lectura.
- El modelo debe permitir determinar si un incidente se originó dentro de un periodo activo.
- La interpretación de timestamps ausentes, inválidos o poco confiables se resolverá mediante la política temporal de la Fase 2.

## Alcance de lectura permitido

Un contacto con autorización activa puede consultar solamente los incidentes críticos autorizados del vehículo y la información necesaria para atenderlos:

- tipo y severidad del incidente;
- estado global, incluida su cancelación cuando corresponda;
- fecha y hora disponibles, junto con su calidad cuando sea necesario;
- ubicación disponible y su calidad o antigüedad;
- identificación básica del vehículo;
- contexto mínimo permitido para atender la emergencia.

La clasificación definitiva de incidentes críticos se coordinará con el modelo canónico y la política FCM. No todo evento emitido por el SDA es visible para los contactos.

## Información restringida

El contacto autorizado no puede consultar ni administrar:

- batería o alimentación;
- conectividad o disponibilidad MQTT;
- diagnósticos;
- eventos técnicos;
- telemetría operativa no necesaria para atender la emergencia;
- configuración o identidad del SDA;
- `deviceId`, IMEI u otros identificadores administrativos, salvo aprobación futura explícita;
- datos administrativos del vehículo;
- provisión, asociación, reemplazo o retiro del SDA;
- otros contactos autorizados.

## Estado global e individual

### Estado global del incidente

Pertenece al incidente y es compartido por los usuarios autorizados. Incluye condiciones como activo, cancelado o finalizado.

### Estado individual del usuario

Pertenece a la interacción de cada usuario con el incidente y puede representar:

- entrega de notificación;
- lectura;
- apertura del detalle;
- reconocimiento personal.

Leer, abrir o reconocer una alerta no cancela ni finaliza el incidente global y no modifica el estado individual de otros usuarios.

## Vigencia e historial de incidentes

- La elegibilidad histórica se determina usando el periodo de autorización vigente cuando ocurrió el incidente.
- La elegibilidad histórica no garantiza acceso actual después de una revocación.
- La revocación no borra la relación ni sus periodos anteriores.
- Una nueva autorización no rellena intervalos durante los cuales el usuario no estuvo autorizado.
- Los incidentes ocurridos durante esos intervalos no se habilitan retroactivamente.
- La política exacta para determinar el tiempo efectivo del incidente se definirá en la Fase 2.

## Separación de mecanismos

### Autorización SmartRoad

Determina qué usuario puede acceder a qué vehículo y a cuáles de sus incidentes críticos.

### Firebase Cloud Messaging

Gestionará tokens, entrega y preferencias de notificación. Estar autorizado no implica que todos los contactos deban recibir exactamente las mismas notificaciones. Esa política se definirá en la fase de FCM.

### Destinatarios SMS del SDA

Son una configuración independiente del firmware. Incorporar, revocar o modificar un contacto en SmartRoad no añade, elimina ni modifica automáticamente números SMS en el SDA.

## Invariantes de seguridad y privacidad

- Una autorización no activa nunca concede acceso.
- Solo el propietario activo del vehículo o un proceso administrativo autorizado puede iniciar una incorporación.
- El backend valida la autoridad del iniciador y controla los cambios del ciclo de vida.
- Una revocación tiene efecto inmediato para nuevas lecturas.
- Conocer un `vehicleId`, `deviceId` o incidente no concede acceso.
- Una relación con un vehículo no concede acceso a otros vehículos.
- Los datos técnicos permanecen restringidos aunque el contacto pueda consultar un incidente.
- El contacto no administra el vehículo, el SDA ni otros contactos.
- Las relaciones históricas no se eliminan por revocación y quedan sujetas a una política futura de retención.
- No existe sincronización implícita entre contactos SmartRoad, FCM y destinatarios SMS.
- La incorporación, aceptación, activación, revocación y expiración deben resultar auditables.

## Decisiones diferidas

Se definirán en tareas posteriores:

- estructura final de nodos y campos RTDB;
- reglas Firebase;
- interfaz y flujo visual de invitación;
- uso de enlaces, códigos u otro mecanismo de incorporación;
- política detallada de preferencias FCM;
- política de retención;
- implementación Flutter y backend;
- cualquier cambio de configuración SMS del firmware, que no forma parte de este flujo.
