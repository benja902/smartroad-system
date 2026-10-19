# Incremento 2 - operaciones locales de contactos

Estado: implementacion local pendiente de revision independiente. No despliegue ni activacion real.

## Contrato y autoridad

Se reutiliza el listener HTTP del backend iniciado por bridge/index.js. GET / conserva la sonda de salud.
POST /contacts/accept recibe solamente vehicleId; el UID procede de verifyIdToken(token, true).
POST /contacts/revoke recibe vehicleId y contactUid; el actor debe ser propietario del vehiculo.
El parametro administrator existe exclusivamente para invocacion administrativa interna, nunca en HTTP.
HTTP rechaza campos adicionales y cuerpos de mas de 2048 bytes. No registra tokens ni payloads.

pending -> active fija activeFrom con ServerValue.TIMESTAMP.
pending o active -> revoked fija revokedAt; revoked es terminal.
Los duplicados preservan las primeras fechas y la revocacion preserva activeFrom.
No se crean invitaciones ni se implementa reactivacion. Aceptar no aumenta el cupo pending/active.
La provision administrativa permanece serializada; no se habilitan altas concurrentes ni se promete un cupo atomico entre herramientas.

## Consistencia y limites

La transaccion opera solo sobre vehicleContacts/{vehicleId}/{contactUid}.
Una suscripcion temporal mantiene el valor en la cache SDK; nunca se sustituye un null por una lectura anterior.
vehicleIds es descubrimiento: se sincroniza desde la relacion actual y se comprueba de nuevo despues de escribir.
Fallo de indice tras commit devuelve estado confirmado con indexSynced=false y programa reparacion. Cualquier fallo posterior al commit, incluidas lecturas, conserva la solicitud. Si no se puede confirmar el estado actual, devuelve transitionCommitted=true, confirmationPending=true, indexSynced=false y status=null; no presenta un snapshot antiguo como autorizacion vigente. Los conflictos posteriores al commit tambien indican transitionCommitted=true en la respuesta de error.
La conciliacion se ejecuta al iniciar y con el temporizador existente de 30 segundos tras fallos; tiene exclusion de ejecuciones superpuestas. Si una solicitud llega durante una ejecucion, queda pendiente y al finalizar se programa otra pasada con el mismo temporizador, sin bucle inmediato ni temporizadores adicionales.
No bloquea callbacks MQTT ni hace transacciones/escrituras en raiz. El recorrido de relaciones se procesa secuencialmente.
Conserva indices legitimos del propietario. Los residuos temporales no autorizan lecturas.
Sin proceso activo o con RTDB caido no se garantiza un tiempo de reparacion.
Una respuesta perdida se resuelve reintentando o consultando la relacion; no se necesitan claves de operacion nuevas.

La propiedad se comprueba antes y despues, pero NO es atomica con la transaccion de relacion.
Un cambio administrativo simultaneo de propietario puede permitir que el antiguo propietario confirme una revocacion; la comprobacion posterior informa OWNERSHIP_CHANGED_REVIEW_REQUIRED sin deshacer la revocacion.
No se garantiza prevenir ese caso con este esquema y transaccion acotada. Las reasociaciones/provision deben permanecer fuera de la ventana de operaciones de contactos hasta definir coordinacion si llegan a habilitarse concurrentemente.
La comprobacion posterior tampoco bloquea futuras escrituras de un administrador. No se utiliza el indice para compensar permisos.

## Bloqueo de integracion real

La preparacion cloud incorpora dos modos de arranque en el mismo backend: mqtt-bridge y http-api. Solo http-api sirve operaciones de contactos. Se conserva el acceso con ambos emuladores en loopback y proyecto demo-. El acceso real requiere habilitacion explicita (desactivada por defecto), identidad de proyecto y despliegue Compose, origen publico HTTPS configurado y comprobacion de IP TCP del proxy privado, Host y protocolo. Caddy es la unica entrada publica; ver bridge/deploy/README.md. Ninguna operacion real se ha habilitado ni desplegado; ver bridge/README.md.
Flutter no configura endpoint por defecto y rechaza HTTP antes de obtener tokens; no sigue redirects.
Los controles mutadores permanecen deshabilitados/ocultos sin endpoint seguro o doble de prueba.
Las reglas LOCALES bloquean contactIncidents incluso para active. No se modificaron las publicadas.
Antes de activar un contacto real: revision independiente, pruebas aprobadas, verificar bloqueo publicado con autorizacion separada y preparar HTTPS confiable. Levantar el bloqueo o habilitar un endpoint real requiere otra autorizacion.
No hay productor/lector de contactIncidents, FCM, nuevas cuentas ni cambios de firmware.
La relacion active por si sola no incorpora al contacto a rutas o proveedores del propietario.

## Verificacion dirigida

Auth y Database Emulator con proyecto demo-smartroad-contacts; no cargar bridge/.env.
Comando: firebase emulators:exec --only database,auth --project demo-smartroad-contacts --config firebase.emulator.json "node --test --test-reporter=spec --test-concurrency=1 --test-timeout=30000 bridge/test/contact_operations.test.js"
Para Flutter y reglas usar scripts/verify.ps1 con rutas dirigidas.
Las pruebas de concurrencia demuestran integridad de los casos ensayados, no ausencia universal de latencia MQTT.
