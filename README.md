# SmartRoad

SmartRoad es un MVP Android en Flutter para presentar los eventos de un único dispositivo SDA instalado en un vehículo y, posteriormente, alertar a su propietario y a contactos autorizados. El firmware vigente se describe en [`manual-sda (4).html`](manual-sda%20(4).html); no se modifica desde este repositorio.

## Qué funciona hoy

- `lib/main.dart` usa Firebase Authentication y Realtime Database (RTDB) reales. El propietario provisionado puede iniciar sesión, leer su vehículo, SDA, eventos y reconocimientos personales. No crea datos demo al iniciar sesión. Las reglas RTDB de Fase 1 están publicadas y se verificaron con una lectura posterior y una prueba manual del propietario.
- `lib/main_dev.dart` usa repositorios mock y simulador, sin inicializar Firebase; sirve para probar pantallas y eventos de forma reproducible.
- `bridge/` contiene el consumidor MQTT local Node.js. Escribe estado operativo y eventos planos en RTDB y proyecta cancelaciones. **Todavía no implementa** la validación integral de payload, modelo canónico robusto, fusión entre transportes ni despliegue cloud. El webhook Iridium, FCM y el flujo funcional del contacto están pendientes. El primer contacto real está provisionado como `pending`, con la cuenta Auth inhabilitada.
- La Fase 1 se cerró conforme a [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md). Las confirmaciones administrativas de identidad del SDA e IMEI no sustituyen los checkpoints físicos formales pendientes.

## Arquitectura objetivo, no estado desplegado

El SDA publica por MQTT a un consumidor persistente; RockBLOCK/Iridium entrega contingencias a un webhook HTTP independiente. Ambos deben converger en el mismo incidente en RTDB. Firebase Authentication define identidad y FCM notificará a destinatarios autorizados; Flutter mostrará experiencias separadas para propietario y contacto. El backend se alojará en Google Cloud. Ver [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/MVP_SCOPE.md`](docs/MVP_SCOPE.md) y el plan. No asumir que webhook, FCM, despliegue cloud o modelo canónico ya existen.

## Ejecución local

Desde la raíz, con Flutter/Dart instalados y dependencias obtenidas con `flutter pub get`:

```powershell
flutter run -t lib/main_dev.dart
```

Para `main.dart`, se necesitan los archivos privados FlutterFire correspondientes al proyecto real (`lib/firebase_options.dart` y `android/app/google-services.json`), conexión a Internet, una cuenta Auth habilitada con perfil RTDB y permisos apropiados. Es una ejecución contra Firebase real: no usarla para crear datos de prueba ni para validar escrituras sin autorización.

```powershell
flutter run -t lib/main.dart
```

El bridge se ejecuta **solo localmente** desde `bridge/`; requiere dependencias (`npm ci`), un `.env` privado en ese directorio y credenciales administrativas externas al repositorio. Ver [`bridge/README.md`](bridge/README.md). El repositorio no contiene ni debe registrar contraseñas, IMEI, UID reales, tokens, cuentas de servicio o valores de configuración privados.

## Validación sin servicios reales

Ejecutar las pruebas en primer plano y observar su progreso. Si no hay salida durante 60 segundos, interrumpir y registrar el último punto conocido.

```powershell
flutter test --no-pub -r expanded test
npm --prefix bridge test
```

Las pruebas de reglas usan Firebase Database Emulator y proyecto ficticio; instrucciones y requisitos en [`test/rtdb_rules/README.md`](test/rtdb_rules/README.md). Las pruebas administrativas locales se describen en [`scripts/admin/README.md`](scripts/admin/README.md). El análisis Dart puede ejecutarse con `dart analyze lib test` cuando el SDK local esté disponible. Ninguno de estos comandos requiere Firebase real ni hardware.

## Fuente de verdad y siguiente tarea

- Comportamiento **actual**: código y pruebas; reglas locales en `database.rules.json` (publicación de Fase 1 documentada en [`docs/RTDB_RULES_PHASE1.md`](docs/RTDB_RULES_PHASE1.md)).
- Contrato vigente del SDA: [`docs/device_contract.md`](docs/device_contract.md) y, ante discrepancia técnica del hardware, `manual-sda (4).html`.
- Modelo RTDB desplegado frente al objetivo: [`docs/RTDB_MODEL.md`](docs/RTDB_MODEL.md).
- Estado y orden de trabajo: [`docs/IMPLEMENTATION_PLAN.md`](docs/IMPLEMENTATION_PLAN.md). El registro de compatibilidad de Fase 1 está en [`docs/RTDB_COMPATIBILITY_MVP.md`](docs/RTDB_COMPATIBILITY_MVP.md).
- **Siguiente tarea:** primer bloque de Fase 2, siguiendo [`docs/PHASE2_INCIDENT_SPEC.md`](docs/PHASE2_INCIDENT_SPEC.md). Resolver primero las `DECISIÓN ABIERTA` que bloquean la política de escritura; después implementar y probar un incremento acotado, sin iniciar Iridium real ni despliegue.
- Límites de autonomía y puntos de intervención humana: [`AGENTS.md`](AGENTS.md).

`manual-sda.html` y los diseños de `docs/design_reference/` son referencias históricas; no sustituyen al contrato vigente ni al comportamiento comprobado.
