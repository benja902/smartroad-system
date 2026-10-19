# AWS-1: preparacion local para una VM Linux

No es un despliegue realizado. No ejecutar contra Firebase/HiveMQ reales sin autorizacion.
Docker Engine con Compose >= 2.24.4. Misma imagen para API y MQTT; Caddy fijado por digest.
No cambian Dockerfile, lockfile, transacciones ni contratos de incidentes.

## Configuracion externa

Configurar en el servidor, fuera del repositorio y de la imagen:

| Variable | Uso |
| --- | --- |
| `PUBLIC_DOMAIN` | Solo hostname DNS definitivo, sin esquema/ruta. Pendiente de decidir. |
| `FIREBASE_PROJECT_ID`, `DATABASE_URL` | Proyecto explicito y URL HTTPS de RTDB. |
| `FIREBASE_CREDENTIALS_FILE` | Ruta absoluta a JSON de cuenta de servicio externo. Archivo ya existente, no lo crea Compose. |
| `CONTACT_OPERATIONS_ENABLED` | Predeterminado `false`. Activacion real requiere autorizacion separada y reglas publicadas seguras. |
| `URBES_IMAGE` | Imagen local preparada, predeterminado `urbes-backend:local`; fijar artefacto aprobado al desplegar. |
| `PROXY_SUBNET`, `PROXY_IP`, `API_IP` | Predeterminados `172.30.42.0/24`, `172.30.42.2` y `172.30.42.3`. Verificar que no colisionen con redes existentes; IPs privadas distintas dentro de esa subred. |
| `MQTT_ENV_FILE` | Solo al migrar MQTT: archivo externo restringido con variables MQTT existentes. No compartirlo con API/Caddy. |

Compose monta la credencial como `/run/secrets/firebase_admin` de solo lectura y pasa esa ruta a ADC.
El archivo debe ser legible por el UID 1000 de Node, sin hacerse legible para todos: propietario/permisos
o ACL restringidos en Linux. El directorio padre tambien debe estar protegido. No guardar el JSON en
Git, variables con su contenido, capas Docker, logs ni argumentos. Los secretos de Compose son montajes
de archivos, no una boveda cifrada. Proteger tambien snapshots y copias; prever rotacion/revocacion.
La cuenta requiere permisos minimos para RTDB y consulta Auth; no crear claves en este incremento.

Sin archivo externo, Compose o el entrypoint fallan; no se sustituye por credenciales personales ni se
silencia el error. Un archivo legible no demuestra IAM ni validez de credenciales: comprobarlos despues
con autorizacion real. `BACKEND_DEPLOYMENT=compose` no carga `.env` dentro del contenedor.

## Red y HTTPS

Solo Caddy publica 80/TCP y 443/TCP. API y MQTT no publican puertos; ambas redes permiten salida
necesaria a Firebase/HiveMQ. Red privada significa aqui sin puertos entrantes publicados, no `internal:true`
(esa ultima impediria el acceso saliente real). Caddy y API comparten una red dedicada; MQTT usa otra.
El API solo confia en la IP TCP exacta de Caddy, nunca en X-Forwarded-For. Se conservan Host esperado,
HTTPS, Firebase verifyIdToken(token, true) y habilitacion explicita. Ninguna cabecera habilita operaciones.
No conectar contenedores ajenos a esa red ni publicar 8080. Un administrador Docker pertenece a la
frontera de confianza del servidor.

Caddy obtiene/renueva certificados ACME cuando DNS, puertos e Internet esten disponibles. No hay
dominio predefinido ni certificados publicos solicitados. `/data` guarda certificados/claves y `/config`
la configuracion autosalvada en volumenes persistentes; Caddyfile se monta de solo lectura. No usar
`down --volumes` en un despliegue real ni habilitar logs de acceso con datos sensibles.
No enviar tokens reales sobre HTTP: el redirect no protege una peticion que ya se envio en claro.

## Preparacion y operacion posterior (requieren autorizacion real)

Construir desde la raiz: `docker build -t urbes-backend:local bridge`.
Inspeccionar configuracion con variables externas ficticias: `docker compose -f bridge/deploy/compose.yaml config`.
Con variables reales esa salida contiene identificadores/rutas: no compartirla ni archivarla.
El arranque normal posterior seria `docker compose -f bridge/deploy/compose.yaml up -d` (solo API/Caddy).

`restart: unless-stopped`, Docker habilitado con systemd al boot y `init: true` en Node permiten recuperar
procesos tras fallo/reboot. Un servicio detenido deliberadamente permanece detenido; healthchecks no
reinician por si solos un proceso bloqueado. `/healthz` y `/readyz` prueban proceso/API o conexion MQTT,
no permisos/disponibilidad Firebase. Los logs JSON se limitan a 3 archivos de 10 MB por servicio.
Los contactos se concilian al iniciar y tras fallos con espera de 30 s y exclusion mutua. Con operaciones
desactivadas no se leen ni concilian contactos reales. La recuperacion depende de VM/red/Firebase
operativos; no garantiza un plazo estricto ni disponibilidad continua.

MQTT queda bajo perfil `mqtt`. Invocar explicitamente su servicio tambien activa ese perfil: no hacerlo
antes del checkpoint de traspaso. Detener el bridge local y su autoinicio antes de iniciar el de AWS;
un clientId fijo no es un mecanismo de exclusion distribuida. La ausencia del archivo MQTT provoca
rechazo por falta de credenciales al intentar arrancarlo, nunca credenciales predeterminadas secretas.

**Pendiente para migracion MQTT:** PUBACK puede preceder a persistencia RTDB; QoS 1/sesion persistente
no garantizan recuperar una fila nunca escrita. Se conserva el comportamiento aprobado, sin corregirlo
en AWS-1. Debe quedar explicito en la aceptacion del checkpoint MQTT y validarse broker/firmware real.

## Verificacion local

`scripts/verify.ps1 -Component bridge -TestPath bridge/test/backend_startup.test.js,bridge/test/contact_recovery.test.js,bridge/test/mqtt_ack.test.js`

Con imagen construida y Docker disponible:
`scripts/verify.ps1 -Component bridge -TestPath bridge/test/compose_deployment.test.js`

La prueba Compose usa proyecto Docker propio, red sin salida, clave RSA ficticia y CA local. No obtiene
certificados publicos ni contacta Firebase/HiveMQ. Comprueba aislamiento, TLS, montaje de solo lectura,
reinicio y persistencia entre recreaciones; elimina sus contenedores/red/volumenes al terminar.
Un reboot real de Linux, firewall externo, renovacion ACME publica, DNS, IAM y cuotas AWS quedan
pendientes del despliegue autorizado. Sin Firebase real, SDA ni celular para estas pruebas locales.

Evidencia AWS-1 local: 32 pruebas de arranque/seguridad, 4 de conciliacion, 2 de MQTT con broker
ficticio, 2 de arranque/recuperacion HTTP con Auth/Database Emulator y 2 de Compose/TLS: 42/42
aprobadas. Imagen reconstruida; sin cambios en Dockerfile, lockfile ni dependencias.
