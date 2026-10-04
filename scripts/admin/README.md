# Provisión administrativa mínima del MVP

Herramienta independiente para **un propietario, un vehículo y un SDA existentes**. No arranca ni modifica el bridge. Reutiliza `firebase-admin` instalado en `bridge/`; no instala nuevas dependencias. Requiere Node con soporte de `--env-file` y las credenciales administrativas existentes fuera del repositorio.

## Dry-run por defecto

Desde la raíz, con la configuración local ya utilizada por el proyecto:

```powershell
node --env-file=bridge/.env scripts/admin/provision_mvp.mjs --existing --confirmed-device-suffix SUFIJO_CONFIRMADO
```

Sustituir `SUFIJO_CONFIRMADO` por un sufijo de al menos cuatro caracteres de la identidad **previamente confirmada físicamente**. La selección exige exactamente un vehículo, toma su SDA y propietario existentes y comprueba el sufijo. No deduce una identidad física a partir de telemetría, no selecciona el segundo registro de `devices` y no inventa IMEI ni contactos.

La URL debe coincidir exactamente con una URL de RTDB configurada en Flutter. El modo predeterminado solo lee RTDB y consulta la existencia y habilitación de las cuentas en Auth. No crea cuentas, no modifica permisos, no publica MQTT y no escribe en Firebase. La salida utiliza alias, no identificadores completos ni valores IMEI. Los errores se muestran como códigos, no como objetos del SDK o contenido de archivos privados.

Si el registro administrativo todavía no existe, propone estos campos:

```text
deviceRegistry/{confirmedDevice}/vehicleId = {existingVehicle}
deviceRegistry/{confirmedDevice}/active = true
```

## Datos opcionales confirmados

Para preparar IMEI o contactos posteriormente, proporcionar `--input RUTA_PRIVADA_JSON` en lugar de `--existing --confirmed-device-suffix`. El archivo con valores reales debe estar **fuera del repositorio**; no pegarlo en logs ni documentación. Ejemplo exclusivamente ficticio del formato:

```json
{
  "ownerUid": "owner-test",
  "vehicleId": "vehicle-test",
  "deviceId": "SDA-TEST-T001",
  "deviceConfirmed": true,
  "rockblockImei": "000000000000001",
  "imeiConfirmed": true,
  "contacts": [{ "uid": "contact-test", "confirmed": true }]
}
```

Omitir `rockblockImei` y `imeiConfirmed` si no existe un IMEI confirmado. Omitir `contacts` si no existen contactos confirmados. El IMEI debe ser una cadena de 15 dígitos; la marca de confirmación es una declaración administrativa, no una comprobación física automatizada. Los contactos deben tener perfil RTDB y cuenta Auth existentes y habilitados. Las relaciones nuevas se preparan exclusivamente como `pending`; las existentes no se activan, reactivan, revocan ni reemplazan. No se añaden índices de acceso a contactos pendientes.

**Las reglas actuales de lectura amplia no se endurecen con esta herramienta.** Una relación `pending` no impide por sí sola las lecturas que ya autorizan esas reglas. No habilitar acceso real de contactos antes de la tarea de reglas y roles correspondiente.

## Aplicación posterior, no autorizada en este bloque

Solo `--apply` habilita escrituras. No se ejecuta como parte de esta entrega. Revalida los datos antes de aplicar y aborta si cambia el plan. Escribe una sola actualización multipath por campos en `deviceRegistry` y, si corresponde, `vehicleContacts`. La repetición con el mismo estado no escribe nada. No escribe en `users`, `vehicles`, `devices`, `events` ni `userIncidentState`; tampoco elimina datos o sustituye IMEI/relaciones incompatibles.

La revalidación y la atomicidad multipath no equivalen a un bloqueo entre la lectura y la escritura: una aplicación futura debe realizarse en una ventana administrativa sin cambios concurrentes en asociaciones. No requiere detener la telemetría del bridge. No se implementa soporte de provisión concurrente ni multiflota.

Antes de retirar `FirebaseBootstrapService`, validar la aplicación de la provisión en una tarea autorizada independiente. No se completa todavía la provisión de producción sin los datos y checkpoints que correspondan.

## Pruebas mínimas locales

```powershell
node --test --test-reporter=spec --test-concurrency=1 scripts/admin/test/provision_mvp.test.mjs
```

Tres pruebas con datos ficticios y límite de cinco segundos por caso: dry-run sin escrituras y salida protegida, repetición idempotente con preservación de datos, y rechazo de asociaciones/identidades incompatibles. La aplicación probada usa solo una base en memoria, **nunca Firebase real**. No requieren SDK, `.env`, internet, bridge, Flutter, celular ni SDA. Ejecutar en primer plano; si pasan 60 segundos sin salida, detener y registrar el último mensaje.

## Validación del 3 de octubre de 2026

- Las tres pruebas mínimas pasaron, con cero fallos. Las comprobaciones `node --check` del CLI, el núcleo y el test también pasaron.
- Se ejecutó una sola vez el CLI en **dry-run real** seleccionando la asociación existente con el sufijo de SDA confirmado físicamente. El proceso terminó correctamente y reportó **0 escrituras**.
- Propuso únicamente añadir `deviceRegistry/{confirmedDevice}/vehicleId`, con la clave del vehículo existente, y `deviceRegistry/{confirmedDevice}/active = true`; ambos campos estaban ausentes.
- No se suministró IMEI confirmado ni contactos confirmados: no se propusieron cambios para ellos.
- No se ejecutó `--apply`, no se modificaron reglas ni cuentas Auth, y no se escribieron datos en Firebase. El segundo registro de `devices`, la telemetría y los incidentes permanecen fuera de las escrituras de esta herramienta.

La aplicación real queda pendiente de revisión y autorización. El bootstrap demo y el cierre de la provisión de producción permanecen como tareas pendientes; esta validación no los completa.
