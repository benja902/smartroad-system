# Alcance aprobado del MVP

## Objetivo

Construir un aplicativo móvil Android que reciba, procese y notifique los reportes generados por el dispositivo SDA, incluyendo la geolocalización del incidente y la comunicación con contactos de emergencia.

El proyecto dispone de un único prototipo SDA físico. El MVP debe demostrar su integración real con una infraestructura cloud autónoma y con el APK instalado en teléfonos Android.

## Roles y módulos

### Propietario o conductor

El propietario o conductor administra el vehículo y consulta tanto incidentes como estado técnico.

Módulos incluidos:

- Inicio.
- Alertas.
- Vehículo.
- Historial.
- Perfil.
- Contactos de emergencia.

Los eventos técnicos, batería baja y estados de conexión están dirigidos principalmente a este rol.

### Contacto de emergencia

El contacto autorizado recibe y consulta información relacionada con emergencias del vehículo al que fue vinculado.

Módulos incluidos:

- Inicio.
- Alertas críticas.
- Historial crítico.
- Perfil.

Los contactos de emergencia no administran el vehículo, el dispositivo SDA, su configuración ni sus diagnósticos técnicos.

## Flujos compartidos

Ambos roles pueden participar, según sus permisos, en estos flujos:

- Emergencia activa.
- Detalle de incidente.
- Geolocalización y mapa.
- Notificaciones mediante Firebase Cloud Messaging.

Un choque grave, una volcadura grave o un SOS puede notificar al propietario y a los contactos autorizados. Los eventos no críticos no deben tratarse automáticamente como emergencias para los contactos.

## Fuera del MVP

- Integración automática con SAMU.
- Integración automática con Bomberos.
- Integración automática con la Policía.
- Portal institucional o centro de monitoreo institucional.
- Publicación en Google Play Store.

Estas capacidades se consideran evolución futura y requieren acuerdos operativos, legales y técnicos adicionales.

## Criterio de entrega

El resultado final del MVP es un APK Android funcional conectado al SDA real y al backend desplegado en Google Cloud, manteniendo Firebase Authentication, Realtime Database y FCM. El dispositivo debe poder reportar eventos y los teléfonos deben poder recibirlos sin que una laptop, VS Code o un proceso local permanezcan encendidos.
