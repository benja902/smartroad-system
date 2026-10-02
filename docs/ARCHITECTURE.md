# Arquitectura objetivo de SmartRoad

## Objetivo arquitectónico

SmartRoad debe operar de forma autónoma con el backend alojado en Google Cloud. El SDA, el backend y el APK Android deben continuar funcionando sin una computadora de desarrollo encendida.

La fuente vigente y versionada del dispositivo es `manual-sda (4).html`. Los manuales anteriores son únicamente históricos. SmartRoad mantiene Firebase Authentication, Firebase Realtime Database y Firebase Cloud Messaging; una migración de RTDB a Firestore requiere una decisión explícita.

## Flujos de entrada

### Canal celular principal

```text
SDA
  -> MQTT/TLS
  -> HiveMQ Cloud
  -> consumidor MQTT persistente en Google Cloud
  -> Firebase Realtime Database
  -> Flutter y Firebase Cloud Messaging
```

El consumidor MQTT mantiene una sesión de larga duración, valida los mensajes, resuelve su dispositivo y propietario, consolida incidentes y actualiza RTDB.

### Canal satelital de contingencia

```text
SDA
  -> RockBLOCK 9603/9603N
  -> Iridium SBD
  -> Ground Control
  -> webhook HTTP en Google Cloud
  -> Firebase Realtime Database
  -> Flutter y Firebase Cloud Messaging
```

MQTT e Iridium son dos entradas para el mismo dominio. Los adaptadores de transporte deben converger en una única operación idempotente de creación o enriquecimiento de incidentes.

### Notificaciones

```text
Primera recepción válida de un incidente crítico
  -> decisión de destinatarios autorizados
  -> FCM
  -> propietario y contactos de emergencia autorizados
```

Una reentrega, un retry del webhook o un enriquecimiento MQTT no debe generar una segunda notificación del mismo incidente.

## Componentes

### SDA

Es la autoridad sobre detección, severidad, secuencia, sensores y estado físico. Publica MQTT, conserva una cola local, puede enviar SMS y utiliza Iridium como contingencia para choques y volcaduras.

### HiveMQ Cloud

Broker MQTT del canal celular. Retiene disponibilidad y estado, entrega eventos QoS 1 y conserva la sesión persistente del consumidor cloud.

### Backend en Google Cloud

El backend tiene dos componentes conceptuales y desplegables por separado:

#### Consumidor MQTT persistente

- Mantiene una conexión MQTT/TLS de larga duración con HiveMQ.
- Usa un `clientId` estable y único y conserva la sesión para recibir el backlog.
- Procesa los topics del SDA y no depende del ciclo de una petición HTTP.
- Requiere una estrategia de instancia única activa o coordinación equivalente para evitar consumidores duplicados.

#### Webhook HTTP de Iridium/Ground Control

- Recibe solicitudes HTTP independientes enviadas por Ground Control.
- Autentica, valida y confirma cada entrega dentro del tiempo exigido por el contrato.
- No mantiene la sesión MQTT ni depende del proceso consumidor.
- Puede escalar y reiniciarse de forma independiente, preservando la deduplicación por `(imei, momsn)`.

Ambos componentes comparten la lógica canónica de validación, asociación, deduplicación y enriquecimiento de incidentes, además de las escrituras privilegiadas y la decisión idempotente de notificación. La selección concreta de servicios administrados, topología, escalado y despliegue en Google Cloud corresponde a la fase 8.

### Firebase Authentication

Gestiona la identidad de propietarios y contactos autorizados. La autenticación no sustituye las asociaciones ni autorizaciones almacenadas y aplicadas por el modelo de seguridad.

### Firebase Realtime Database

Es el backend de datos actual. Almacena identidad y relaciones de usuarios, contactos, vehículos y dispositivos, además de estado operativo e incidentes normalizados.

El esquema final y sus campos se definirán durante la fase de modelo de datos y seguridad. Las claves y transacciones deben garantizar deduplicación por incidente y por entrega satelital.

### Firebase Cloud Messaging

Entrega alertas aun cuando Flutter está minimizado o cerrado. La emisión se produce solo después de aceptar por primera vez un incidente crítico válido.

### Flutter Android

Consume RTDB y FCM; no se conecta directamente a MQTT, Ground Control ni Iridium. Presenta información según el rol y nunca decide si el firmware detectó un accidente.

## Conceptos del dominio

### Propietario

Usuario responsable del único vehículo/prototipo del MVP. Administra sus datos, el vehículo, los contactos autorizados y consulta incidentes y estado técnico.

### Contacto autorizado

Usuario vinculado por el propietario para recibir y consultar emergencias críticas. No administra el vehículo ni el SDA y no accede por defecto a eventos técnicos.

### Vehículo

Entidad del aplicativo asociada al propietario y al dispositivo físico. Contiene la identidad vehicular necesaria para presentar los incidentes.

### Dispositivo

Representación del SDA físico. Vincula su `deviceId` con el vehículo y, cuando corresponda, con el IMEI de RockBLOCK. Su telemetría es de solo lectura para clientes móviles.

### Incidente

Registro canónico identificado por `(deviceId, seq)`. Puede crearse desde MQTT o Iridium y enriquecerse después desde el otro canal. Conserva su origen, estado de cancelación, reconocimiento y notificación sin duplicarse.

### Notificación

Entrega dirigida a uno o más usuarios autorizados. Está asociada a un incidente y debe ser idempotente. Los destinatarios dependen del tipo, severidad, rol y autorización vigente.

## Límites de confianza

- El SDA produce eventos, pero el backend valida su contrato.
- Ground Control debe autenticarse antes de aceptar un mensaje satelital.
- El backend usa credenciales administrativas; Flutter opera bajo reglas RTDB por usuario y rol.
- Secretos MQTT, credenciales cloud y material de validación JWT nunca se almacenan en el cliente ni en el repositorio.
- Los mocks permanecen separados de los adaptadores de producción.

## Decisiones vigentes

- Aplicación objetivo: Android/Flutter.
- Plataforma de alojamiento del backend: Google Cloud.
- El consumidor MQTT persistente y el webhook HTTP de Ground Control son servicios separados.
- Autenticación: Firebase Authentication.
- Base de datos: Firebase Realtime Database.
- Identidad canónica de incidente: `(deviceId, seq)`.
- Identidad de entrega Iridium: `(imei, momsn)`.
- MQTT es el canal principal; Iridium es contingencia.
- FCM es necesario para recepción con la app en background o cerrada.
- No se diseña todavía el esquema final completo de RTDB.
- La selección y el despliegue de los servicios concretos de Google Cloud permanecen en la fase 8.
