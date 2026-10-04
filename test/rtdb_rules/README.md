# Pruebas locales de reglas RTDB — Fase 1

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

La suite comprueba:

- lectura del estado propio y rechazo del ajeno o sin autenticación;
- escritura propia mediante el `userId` histórico o `vehicleId → ownerId`, como alternativas compatibles;
- evento existente y rechazo de eventos no asociados al usuario;
- únicamente `acknowledged` booleano, sin campos adicionales ni borrado;
- rechazo atómico de escrituras múltiples que incluyan rutas ajenas o campos adicionales;
- preservación del evento canónico y sus cancelaciones;
- índices de `events`, consultas duales restringidas al propietario y rechazo del reconocimiento global;
- lecturas positivas y negativas de propietario, contacto `pending`, `active` y `revoked`, ajenos y usuarios sin autenticar;
- escritura exclusiva del backend para perfiles, asociaciones, SDA, eventos, proyecciones y entregas satelitales;
- necesidad del índice administrativo `ownerVehicleId` para excluir a los contactos de la consulta histórica por `userId`.

No hace falta ejecutar `main_dev.dart` ni `main.dart`, conectar el celular, iniciar el bridge o usar el SDA. Las reglas nuevas se prueban **solo** en Emulator; no ejecutar `firebase deploy` como parte de este paso. `RTDB_RULES_PHASE1.md` documenta el nuevo índice administrativo requerido antes de una publicación futura.

Las pruebas verifican que `vehicles` y `events` ya no admitan escrituras de clientes y que los contactos no lean los eventos canónicos ni datos técnicos. La proyección `contactIncidents` aún no se produce en Firebase real; su lectura se prueba únicamente con datos ficticios.

Antecedente: el 2 de octubre de 2026 pasaron **18 pruebas** del estado individual con las reglas mínimas anteriores. El 4 de octubre de 2026 la suite ampliada de Fase 1 terminó con **30 pruebas aprobadas y 0 fallos** en Emulator, incluidos ambos archivos `*.test.mjs`. El script de pruebas devolvió código 0; en este entorno la CLI de Firebase mostró después un error de cierre y devolvió código 1. Ese error posterior no corresponde a una prueba fallida ni a reglas publicadas. No se modificó la configuración de la CLI ni se ejecutó contra Firebase real.
