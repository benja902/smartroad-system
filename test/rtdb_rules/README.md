# Pruebas locales de userIncidentState — Paso 3

Requisitos: Node.js 20 o posterior, Firebase CLI y Java 21 o posterior para la CLI actual. Las dependencias de pruebas son independientes del bridge y de Flutter. El Database Emulator utiliza `127.0.0.1:19000`.

Desde `D:\smartroad`, instalar desde el lockfile:

```powershell
npm --prefix test/rtdb_rules ci --no-audit --no-fund
```

Ejecutar en primer plano:

```powershell
firebase emulators:exec --only database --project demo-smartroad-rules --config firebase.emulator.json "npm --prefix test/rtdb_rules test"
```

Si `java -version` muestra Java 17, puede usarse el Java compatible incluido en Android Studio únicamente en la terminal actual (si está instalado en esta ruta):

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$env:FIREBASE_CLI_DISABLE_UPDATE_CHECK = 'true'
$env:DEBUG = ''
firebase.cmd emulators:exec --non-interactive --only database --project demo-smartroad-rules --config firebase.emulator.json "npm --prefix test/rtdb_rules test"
```

El runner Node usa `--test-reporter=spec` para mostrar cada caso y limita cada prueba a 30 segundos. `-r expanded` corresponde a Flutter y no se usa con este runner. Si no hay salida durante 60 segundos, detener con `Ctrl+C` y registrar el último mensaje.

La configuración carga `database.rules.json` únicamente en el emulador. El proyecto `demo-smartroad-rules`, el host local obligatorio y los datos ficticios separan estas pruebas de la instancia real. El script rechaza ejecutarse sin `FIREBASE_DATABASE_EMULATOR_HOST` local. Los datos se restablecen entre casos y el emulador se apaga al finalizar.

Se comprueban:

- lectura del estado propio y rechazo del ajeno o sin autenticación;
- escritura propia mediante el `userId` histórico o `vehicleId → ownerId`, como alternativas compatibles;
- evento existente y rechazo de eventos no asociados al usuario;
- únicamente `acknowledged` booleano, sin campos adicionales ni borrado;
- rechazo atómico de escrituras múltiples que incluyan rutas ajenas o campos adicionales;
- preservación del evento canónico y sus cancelaciones;
- permisos actuales e índices de `events`, incluidas ambas consultas.

No hace falta ejecutar `main_dev.dart` ni `main.dart`, conectar el celular, iniciar el bridge o usar el SDA. La validación de las reglas no activa la lectura personal ni cambia la escritura de “Ya lo vi”. No ejecutar `firebase deploy` como parte de este paso.

Las reglas previas de `vehicles` y `events` permanecen sin cambios. Esta autorización mínima no sustituye el endurecimiento posterior de asociaciones y roles: en particular, la asociación de propietario todavía depende de los permisos actuales de escritura de `vehicles`. No se otorgan permisos nuevos a contactos.

Resultado registrado el 2 de octubre de 2026: **18 pruebas aprobadas, 0 fallos**, ejecutadas en primer plano con Firebase CLI 15.16.0, Database Emulator 4.11.2 y el Java 25 incluido en Android Studio. No se publicaron reglas.
