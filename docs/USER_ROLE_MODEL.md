# Modelo conceptual de usuarios y relaciones

## Propósito

Este documento define cómo la identidad autenticada se relaciona con vehículos, dispositivos e incidentes en el MVP de SmartRoad. Es un modelo conceptual: no define nodos RTDB, reglas Firebase, pantallas ni código.

## Identidad y permisos efectivos

Firebase Authentication identifica a cada usuario mediante su `uid`. El `uid` no determina por sí solo un rol global ni concede acceso a vehículos.

Los permisos efectivos se derivan de relaciones autorizadas entre el usuario y cada vehículo. Por ello, un mismo usuario puede mantener simultáneamente relaciones diferentes, por ejemplo:

- propietario del vehículo A;
- contacto autorizado del vehículo B.

`propietario` y `contacto autorizado` son tipos de relación usuario–vehículo, no roles globales mutuamente excluyentes.

## Entidades conceptuales

### Usuario autenticado

Identidad reconocida por Firebase Authentication. Puede participar en una o varias relaciones autorizadas con vehículos diferentes.

### Vehículo

Entidad funcional del aplicativo. Agrupa sus datos permitidos, el SDA asociado, los contactos autorizados y los incidentes que le corresponden.

### Dispositivo SDA

Representación del SDA físico asociado a un vehículo. Expone al propietario únicamente la información operativa autorizada. Su identidad, provisión y configuración crítica permanecen bajo control administrativo.

### Relación usuario–vehículo

Asociación autorizada que determina qué puede consultar o administrar un usuario respecto de un vehículo concreto. Sus tipos iniciales son:

- propietario;
- contacto autorizado.

### Autorización de contacto

Relación que permite a un usuario consultar emergencias críticas de un vehículo sin concederle administración del vehículo ni del SDA.

### Incidente

Registro canónico y compartido de un evento reportado por el SDA. Su estado global no depende de qué usuarios lo hayan leído o recibido.

### Estado individual del usuario

Información asociada a la interacción de un usuario concreto con un incidente, como lectura, entrega de notificación, apertura o reconocimiento personal.

## Restricciones iniciales del MVP

- Cada vehículo puede tener como máximo un propietario activo.
- Cada vehículo puede tener uno o varios contactos autorizados.
- Un usuario puede mantener relaciones diferentes con distintos vehículos.
- Un usuario no queda limitado globalmente a un único tipo de relación.
- El MVP no necesita soportar varios propietarios activos simultáneos para el mismo vehículo.

## Ciclo de vida conceptual de las relaciones

Una relación puede encontrarse en uno de estos estados:

- `pending`: propuesta o invitación todavía no aceptada, cuando el flujo requiera aceptación;
- `active`: relación vigente que puede otorgar permisos;
- `revoked`: relación revocada, sin acceso futuro al vehículo.

El mecanismo concreto de invitación, aceptación y revocación se definirá posteriormente. Una revocación debe retirar el acceso futuro sin alterar el registro global de los incidentes.

## Matriz conceptual de permisos

| Capacidad | Propietario del vehículo | Contacto autorizado | Backend o proceso administrativo |
|---|---|---|---|
| Consultar datos funcionales del vehículo | Sí | No | Sí |
| Administrar datos funcionales permitidos del vehículo | Sí | No | Sí |
| Gestionar contactos autorizados del vehículo | Sí | No | Sí |
| Consultar el SDA asociado | Sí | No | Sí |
| Consultar estado técnico autorizado, batería, conectividad e información operativa permitida | Sí | No | Sí |
| Consultar incidentes del vehículo | Sí | Solo incidentes críticos autorizados | Sí |
| Consultar la ubicación de un incidente permitido | Sí | Sí, solo para incidentes críticos autorizados | Sí |
| Consultar eventos técnicos y diagnósticos | Sí, dentro de la información autorizada | No | Sí |
| Modificar configuración crítica del SDA | No | No | Sí |
| Provisionar o reasociar `deviceId` | No | No | Sí |
| Provisionar o reasociar IMEI | No | No | Sí |
| Modificar la identidad del dispositivo | No | No | Sí |
| Ejecutar operaciones administrativas sensibles | No | No | Sí |

La relación de propietario no convierte a Flutter en una herramienta de provisión del SDA. La asociación o reasociación de `deviceId` e IMEI, la configuración crítica, la identidad del dispositivo y las operaciones administrativas sensibles quedan reservadas al backend o a un proceso administrativo autorizado.

## Estado global e individual del incidente

### Estado global

Representa la condición compartida del incidente, por ejemplo:

- activo;
- cancelado;
- finalizado.

La cancelación procede del evento SDA correspondiente y afecta al incidente global. Leer, abrir o reconocer un incidente desde Flutter no lo cancela ni modifica su condición para otros usuarios.

### Estado individual por usuario

Representa la relación de un usuario concreto con el incidente, por ejemplo:

- notificación entregada;
- incidente leído;
- detalle abierto;
- reconocimiento personal.

Este estado no modifica el estado global del incidente ni el estado individual de los demás usuarios.

## Invariantes de autorización

- Conocer un `uid`, `vehicleId`, `deviceId` o IMEI no concede acceso.
- Los permisos siempre se evalúan para la relación entre el usuario autenticado y el vehículo consultado.
- Una relación con un vehículo no concede acceso a otros vehículos.
- Un contacto autorizado accede únicamente a incidentes críticos permitidos y a su ubicación.
- Un contacto autorizado no consulta batería, conectividad, diagnósticos ni eventos técnicos.
- Un contacto autorizado no administra el vehículo, el SDA ni sus contactos.
- Los datos técnicos permanecen restringidos aunque estén asociados con un incidente visible para el contacto.
- La revocación de una relación impide accesos posteriores.
- La lectura o el reconocimiento individual no cancelan ni finalizan el incidente global.

## Decisiones diferidas

Se definirán en tareas posteriores:

- estructura final de nodos y campos RTDB;
- reglas Firebase;
- flujo concreto de invitación y aceptación;
- pantallas y navegación;
- implementación Flutter y backend.
