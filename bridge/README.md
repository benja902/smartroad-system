# Bridge MQTT → Firebase Realtime Database

## Estado actual

Una base de codigo Node.js comparte dos modos de arranque. `BACKEND_MODE=mqtt-bridge` (predeterminado local) mantiene una conexion MQTT TLS con sesion persistente y consume `availability`, `status`, `position` y `event`; el validador contrasta `id` con el topic y `event_writer.js` conserva eventos en `events/{deviceId}_{seq}` mediante transacciones. Los bloques opcionales malformados se descartan con diagnósticos de código fijo. La conciliación local de cancelaciones de 2.1c está aprobada; la clasificación Flutter de tipos desconocidos pertenece a 2.1d. **No hay despliegue cloud validado** ni webhook Ground Control/Iridium.

## Ejecución local

Usar Node 24, instalar dependencias desde el lockfile y ejecutar desde `bridge/`. En local se carga `.env` solo si existe; las variables ya definidas tienen prioridad. Compose utiliza variables explicitas y ADC con un archivo externo montado de solo lectura (ver `deploy/README.md`):

```powershell
cd bridge
npm ci
npm start
```

`bridge/.env` es privado y está ignorado. Debe contener `DATABASE_URL`, `MQTT_HOST`, `MQTT_PASS` y, si difieren de los valores predeterminados, `MQTT_USER` y `MQTT_PREFIX`. Se requieren credenciales de Firebase Admin fuera del repositorio, disponibles para Application Default Credentials. No copiar valores reales a documentación, comandos compartidos, logs o fixtures. Este arranque **conecta con servicios reales y escribe RTDB**; requiere autorización y configuración deliberadas. Para trabajo autónomo usar pruebas locales y Emulator, no este comando.

`index.js` valida la configuracion antes de inicializar Firebase o conectar a MQTT. Los errores de arranque muestran codigos, nunca valores de configuracion. No se inicia el backend real durante las pruebas.

## Modos y configuracion local preparada

| Variable | Contrato |
| --- | --- |
| `BACKEND_MODE` | `mqtt-bridge` o `http-api`; desconocidos abortan. En Compose es obligatoria; localmente se conserva MQTT por defecto. |
| `BACKEND_DEPLOYMENT` | `local` (predeterminado) o `compose`; Compose no carga `.env` interno y exige un archivo ADC externo legible. |
| `DATABASE_URL` | URL HTTPS de RTDB, sin credenciales, query o fragmento. |
| `FIREBASE_PROJECT_ID` | Proyecto explicito requerido por API; tambien admite `GCLOUD_PROJECT`/`GOOGLE_CLOUD_PROJECT` si coinciden. MQTT local puede conservar la resolucion ADC existente. |
| `PORT` | Entero 1-65535, predeterminado 8080. Escucha en `0.0.0.0`. |
| `CONTACT_OPERATIONS_ENABLED` | Solo `true`/`false`, predeterminado `false`. No habilitar ahora sobre datos reales. |
| `CONTACT_PUBLIC_URL` | En API Compose exige origen HTTPS DNS, sin rutas ni credenciales. No exige `run.app` ni variables `K_*`. |
| `HTTP_TRUST_PROXY_IP` | IPv4 privada exacta del proxy, configurada tambien en Compose; no confia en IPs reenviadas por el cliente. |
| `MQTT_HOST`, `MQTT_PASS`, `MQTT_USER`, `MQTT_PREFIX` | Solo MQTT; API no las exige ni conecta al broker. El prefijo es un unico nivel sin comodines. |

`http-api` no importa el modulo MQTT, no ejecuta conciliacion de incidentes y no necesita sus secretos. Sus operaciones y conciliacion de contactos se habilitan con ambos emuladores locales/proyecto ficticio, o con habilitacion real explicita. Con operaciones deshabilitadas no se hacen lecturas de contactos al arrancar.

Las rutas GET `/`, `/healthz` y `/readyz` comprueban proceso/escucha en API; no acreditan permisos IAM ni disponibilidad de Firebase. En MQTT conservan la comprobacion de conexion al broker. El apagado cancela el temporizador y cierra servidor/cliente.

Cada operacion verifica el token Firebase, incluidas revocacion e inhabilitacion. En Compose solo se aceptan operaciones desde la IP TCP privada configurada de Caddy, con Host del origen configurado y `X-Forwarded-Proto: https`. Caddy termina TLS y sobrescribe la cabecera; la API no publica puertos. No se debe exponer el puerto de la API ni confiar solo en cabeceras de clientes. Un `https` falsificado no habilita un proceso con operaciones desactivadas. No se desactiva validacion TLS de Flutter.

No hay rutas ni implementacion Iridium; el modo HTTP y la imagen quedan reutilizables para incorporarlo despues con autenticacion independiente.


## Pruebas locales sin broker ni Firebase reales

Desde la raíz del repositorio, en primer plano:

```powershell
npm --prefix bridge test
```

El runner nativo de Node muestra progreso con `--test-reporter=spec`; `-r expanded` corresponde a Flutter. Si pasan 60 segundos sin salida, detener con `Ctrl+C` e informar el último punto conocido. La suite usa dobles de base y asociación y un broker MQTT local ficticio para comprobar PUBACK; no carga `.env`, servicios reales ni SDA. Las pruebas con Firebase Admin se omiten salvo dentro de Database Emulator con `FIREBASE_DATABASE_EMULATOR_HOST=127.0.0.1:19000` y `GCLOUD_PROJECT=demo-smartroad-bridge`. No emplear un proyecto real para esas pruebas.

## Cancelaciones y límite de entrega MQTT (2.1c local)

La fila `cancel` conserva su propia primera `receivedAt`. Su proyección en el original usa ese valor ya confirmado como `cancelledAt`; los duplicados no lo mueven y las cancelaciones incompatibles no reemplazan la primera proyección. Al iniciar el bridge se revisan las filas `cancel` de `events` y se concilian con transacciones idempotentes. Si la segunda escritura falla mientras el proceso sigue activo, se informa el fallo y se reintenta la conciliación a los 30 segundos; tras reinicio se repite el barrido. Esto usa RTDB existente y el alcance previsto de un SDA. No hay transacción atómica entre las dos filas.

Una prueba con un broker MQTT 3.1.1 **local y ficticio** confirma que MQTT.js envía PUBACK de QoS 1 antes de que termine el listener asíncrono y antes de conocer el resultado de RTDB. Si falla la escritura de la propia fila del evento, el bridge informa el error, pero esa entrega puede no repetirse: `clean:false` y QoS 1 no garantizan persistencia en RTDB ni recuperación tras una caída. Si la fila `cancel` sí quedó guardada, la conciliación anterior recupera su proyección sin depender de una nueva entrega MQTT. El comportamiento del broker productivo, de su sesión y del SDA físico no se ha probado aquí.

## Preparacion AWS-1: Docker Compose y HTTPS

Ver [`deploy/README.md`](deploy/README.md), [`deploy/compose.yaml`](deploy/compose.yaml) y [`deploy/Caddyfile`](deploy/Caddyfile). Preparacion local: no hay infraestructura creada ni despliegue validado. Una imagen sirve ambos modos; inicialmente solo API y Caddy. MQTT queda en el perfil explicito `mqtt` y no debe coexistir con el consumidor local.

Se conserva Dockerfile, lockfile, usuario no root y lista de archivos permitidos en `.dockerignore`. Construccion local: `docker build -t urbes-backend:local bridge`. No hacer push. El empaquetado no contiene claves ni configuracion privada.

La VM mantendra los temporizadores mientras este operativa; no hay garantia de reparacion durante caidas. Antes del uso real se requieren autorizacion, credito/region, dominio/TLS publico, firewall, credencial externa con permisos minimos y reglas publicadas que bloqueen temporalmente `contactIncidents`.

## Límites

No utiliza Firestore. No publica comandos `ping`, `position` ni `diag` hacia el SDA. No implementa FCM, webhook Iridium ni consultas de contacto. La referencia técnica del dispositivo es `docs/device_contract.md` y, ante discrepancia de firmware, `manual-sda (4).html`.

## Evidencia anterior (previa a AWS-1)

- Arranque/configuracion/transporte y empaquetado: 26 pruebas dirigidas aprobadas; regresiones relacionadas: 4 de conciliacion y 2 de MQTT con broker ficticio aprobadas.
- Runtime HTTP con Auth/Database Emulator, proyecto ficticio: 2 pruebas aprobadas (autenticacion y recuperacion tras reinicio sin tocar incidentes).
- Imagen construida localmente; 3 pruebas de contenedor aprobadas sin red, credenciales ni secretos montados. API inicia sin .env ni MQTT, mutaciones desactivadas, configuraciones invalidas rechazadas. Contenedores y emuladores cerrados; imagen urbes-backend:local conservada para revision, sin push.
- Correccion dirigida posterior: Firebase Admin 13.10.0, gRPC 1.14.6 y Busboy 3.2.3; cero altas y nueve moderadas pendientes. AWS-1 no modifica estas dependencias.
- No se validaron TLS publico, ADC/IAM o disponibilidad en infraestructura real. Las pruebas locales con proxy usan dobles; no equivalen a un despliegue.

Pruebas repetibles: scripts/verify.ps1 -Component bridge -TestPath bridge/test/backend_startup.test.js,bridge/test/contact_recovery.test.js,bridge/test/mqtt_ack.test.js. Docker requiere motor local e imagen construida: scripts/verify.ps1 -Component bridge -TestPath bridge/test/container_smoke.test.js. Emulator: firebase emulators:exec --only database,auth --project demo-smartroad-startup --config firebase.emulator.json "node --test --test-reporter=spec --test-timeout=30000 bridge/test/backend_emulator.test.js".
