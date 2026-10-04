# Reglas RTDB de la Fase 1

Estas reglas están en `database.rules.json` y se probaron con `test/rtdb_rules/` y el proyecto ficticio `demo-smartroad-rules`. Se publicaron en Firebase real el 4 de octubre de 2026, después de provisionar el índice administrativo del propietario. La publicación no modificó datos de RTDB ni habilitó la cuenta del contacto.

Validación local del 4 de octubre de 2026: **30/30 pruebas aprobadas** en Firebase Database Emulator. El script de pruebas terminó con código 0; la CLI envolvente devolvió código 1 por un error posterior al apagar el emulador, descrito en el README de pruebas.

## Por qué se requiere `users/{uid}/ownerVehicleId`

Se probó primero una versión sin nuevo índice, usando solo las relaciones existentes:

- `events.orderByChild('userId').equalTo(auth.uid)` para compatibilidad histórica;
- `events.orderByChild('vehicleId').equalTo(vehicleId)` con `vehicles/{vehicleId}/ownerId == auth.uid` para eventos nuevos;
- `deviceRegistry → vehicles → ownerId` para el SDA.

El Emulator confirmó que la consulta histórica también se autoriza para un contacto que consulta su propio UID. En el fixture, un evento etiquetado por error con ese `userId` se vuelve legible aunque el contacto esté `pending`. La regla de cada `events/{eventKey}` no corrige una lectura autorizada en el nodo padre: las [reglas RTDB no actúan como filtros](https://firebase.google.com/docs/database/security/core-syntax). El resultado contradice el requisito de no dar acceso directo a `events` a los contactos. `vehicleIds` tampoco distingue roles, porque un contacto `active` podría tener ese índice.

Por ello se añadió `users/{uid}/ownerVehicleId`, campo administrativo exclusivo del propietario del único vehículo MVP. Las reglas comprueban el índice **y** `vehicles/{ownerVehicleId}/ownerId == auth.uid`. Un UID o un índice inventado no basta. La consulta histórica sigue exigiendo `query.orderByChild == 'userId'` y `query.equalTo == auth.uid`; la consulta nueva exige `vehicleId == ownerVehicleId`. Se conservaron los índices de `events` y `vehicles`.

Antes de publicar, el campo se aplicó únicamente al perfil del propietario real. Una lectura confirmó el vehículo actual y un dry-run independiente propuso cero cambios. No se añadió al perfil del contacto.

## Alcance de las reglas publicadas

- Propietario: lee su perfil, consulta su vehículo por `ownerId`, consulta eventos por `userId` y `vehicleId`, lee el SDA activo enlazado y lista los contactos de su vehículo. No puede listar toda la base ni escribir asociaciones, telemetría o eventos.
- Contacto `pending`: solo puede leer su perfil y su propia relación; no `events`, `devices` ni `contactIncidents`.
- Contacto `active`: puede leer su perfil, su propia relación y la proyección `contactIncidents/{vehicleId}`. Esa proyección todavía no se implementa en producción; su contenido seguro será responsabilidad del backend antes de habilitar cuentas reales. No accede a `events` ni a datos técnicos.
- Contacto `revoked`, ajenos y usuarios sin autenticar: sin acceso a proyecciones críticas.
- Escrituras de cliente: solo el estado individual `userIncidentState/{auth.uid}/{eventKey}/acknowledged` del propietario, con validación booleana y asociación. Los demás nodos son de escritura exclusiva del backend/administración. El reconocimiento global en `events` queda cerrado.

El fallback histórico por `userId` depende de que el backend haya asignado ese campo correctamente; una consulta RTDB no puede validar cada resultado de la colección. En el MVP de un vehículo se conserva para no perder los eventos anteriores. La política de ingesta y colisiones pertenece a la Fase 2.

## Publicación y validación

- El destino se confirmó contra `firebase.json`, `firebase_options.dart`, la configuración Android y las credenciales administrativas: todos apuntaban al mismo proyecto real y a su RTDB.
- Justo antes de publicar, las reglas desplegadas coincidían con la versión base del repositorio, sin diferencias ajenas. El archivo local proponía 20 cambios de reglas; los índices de `events` y `vehicles` permanecían iguales.
- La publicación autorizada terminó correctamente. Una lectura posterior confirmó coincidencia exacta entre las reglas desplegadas y `database.rules.json`.
- El usuario probó después `main.dart` con la cuenta real del propietario y no reportó anomalías. La cuenta del contacto sigue inhabilitada; no se probó acceso real de contacto ni se implementó la proyección segura de incidentes.
- No se modificaron datos durante la publicación, no se limpiaron datos demo y no se sincronizaron contactos SmartRoad con los números SMS del SDA.

Las pruebas de Emulator y la prueba manual del propietario no sustituyen las futuras pruebas de acceso del contacto ni la revisión de las reglas cuando se implemente su flujo completo.
