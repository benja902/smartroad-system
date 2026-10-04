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

Omitir `rockblockImei` y `imeiConfirmed` si no existe un IMEI confirmado. Omitir `contacts` si no existen contactos confirmados. El IMEI debe ser una cadena de 15 dígitos; la marca de confirmación es una declaración administrativa, no una comprobación física automatizada. Los contactos deben tener perfil RTDB y cuenta Auth existentes e inhabilitados mientras las reglas actuales sigan permitiendo lecturas amplias. Se admiten hasta tres relaciones `pending` o `active` por vehículo; las `revoked` no ocupan cupo. Las relaciones nuevas se preparan exclusivamente como `pending`; las existentes no se activan, reactivan, revocan ni reemplazan. No se añaden índices de acceso a contactos pendientes.

**Las reglas actuales de lectura amplia no se endurecen con esta herramienta.** Una relación `pending` no impide por sí sola las lecturas que ya autorizan esas reglas. No habilitar acceso real de contactos antes de la tarea de reglas y roles correspondiente.

## Preparación de perfiles para contactos reales

El primer contacto debe tener una cuenta Firebase Auth propia. En Firebase Console, crear la cuenta con su correo y una contraseña inicial aleatoria privada, **inhabilitarla inmediatamente** y conservar su UID fuera del repositorio. No enviar todavía el correo de restablecimiento ni invitar al contacto a entrar; con las reglas actuales, una cuenta habilitada podría consultar datos ajenos a su futuro rol. Si la cuenta ya existe, no duplicarla: verificar su identidad y dejarla inhabilitada mientras se prepara la provisión. La contraseña no se entrega a esta herramienta ni se registra en archivos del proyecto.

Tras confirmar cada cuenta, preparar un archivo JSON privado fuera del repositorio con uno, dos o tres contactos:

```json
{
  "contacts": [
    { "uid": "<UID_AUTH_CONFIRMADO>", "name": "<NOMBRE_CONFIRMADO>", "confirmed": true }
  ]
}
```

El correo se toma directamente de Firebase Auth; no se duplica en ese archivo. `provision_contact_profiles.mjs` comprueba la cuenta inhabilitada, el vehículo y SDA únicos, la asociación ya provisionada, el límite de tres y los conflictos de perfil. Su dry-run predeterminado no escribe; oculta UID, nombre y correo en la salida. Solo propone campos faltantes `users/{uid}/name` y `users/{uid}/email`, preservando todos los demás campos. `--apply` queda para una ejecución posterior expresamente revisada; no se usa al preparar la cuenta.

```powershell
node --env-file=bridge/.env scripts/admin/provision_contact_profiles.mjs --input <RUTA_PRIVADA_FUERA_DEL_REPOSITORIO> --confirmed-device-suffix <SUFIJO_CONFIRMADO>
```

Una vez comprobados por lectura los perfiles, la herramienta principal puede proponer como máximo tres rutas `vehicleContacts/{vehicleId}/{uid}/status = pending`. No añade `vehicleIds` al perfil ni activa acceso; habilitar las cuentas y enviar el restablecimiento de contraseña esperan a las reglas y roles correspondientes.

Para reutilizar el mismo archivo privado de perfiles, sin copiar identificadores a otro archivo, ejecutar el siguiente dry-run. Comprueba de nuevo que el nombre y correo del perfil coincidan con el archivo y con Auth, y que la cuenta siga inhabilitada. La única escritura que podría proponerse para un contacto ya preparado es `vehicleContacts/{existingVehicle}/{confirmedContact1}/status = pending`:

```powershell
node --env-file=bridge/.env scripts/admin/provision_mvp.mjs --contacts-input <RUTA_PRIVADA_FUERA_DEL_REPOSITORIO> --confirmed-device-suffix <SUFIJO_CONFIRMADO>
```

## Aplicación controlada

Solo `--apply` habilita escrituras tras revisión del dry-run. Revalida los datos antes de aplicar y aborta si cambia el plan. La herramienta principal escribe una sola actualización multipath por campos en `deviceRegistry` y, si corresponde, `vehicleContacts`. La repetición con el mismo estado no escribe nada. No escribe en `users`, `vehicles`, `devices`, `events` ni `userIncidentState`; tampoco elimina datos o sustituye IMEI/relaciones incompatibles. La herramienta separada de perfiles solo puede añadir `users/{uid}/name` y `users/{uid}/email` cuando faltan.

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

Esta fue la validación inicial, anterior a las aplicaciones autorizadas. Posteriormente se aplicaron y comprobaron por lectura la asociación propietario–vehículo–SDA y el IMEI confirmado. Para el primer contacto real se aplicaron exclusivamente los campos `users/{uid}/name` y `users/{uid}/email`, seguidos de `vehicleContacts/{vehicleId}/{uid}/status = pending`. En ambos pasos el dry-run posterior propuso cero cambios. Las pruebas locales de las dos herramientas terminaron con **9 aprobadas y 0 fallos**, incluidas la idempotencia y la capacidad máxima de tres contactos. No se crearon otros dos usuarios de prueba. La cuenta del contacto sigue inhabilitada; activación, reglas de acceso y pantallas pertenecen a tareas posteriores.
