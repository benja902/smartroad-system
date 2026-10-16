# Escena Flutter DEV — Incremento 1

Fuente: Variante D (`beacon`) de Motion Prototype 01, instantánea aprobada de `composition_v3` a 2160 ms. Es una escena estática de revisión, anterior a la reacción. No es una nueva propuesta artística ni el primer fotograma del futuro Splash.

La especificación, alcance y garantías están en [PREMIUM_SPLASH_LOGIN_FLUTTER_SPEC.md](../../../PREMIUM_SPLASH_LOGIN_FLUTTER_SPEC.md).

## Recursos y regeneración

`generate_geometry.py` usa únicamente la biblioteca estándar de Python. Comprueba la procedencia contra el manifiesto de v3; genera 221 formas agrupadas en 15 capas para `lib/screens/dev/premium_scene/premium_scene_geometry.g.dart`. No modificar ese archivo a mano. No se añade un parser SVG al runtime Flutter.

Desde la raíz del repositorio:

```powershell
python docs/ui_ux/premium_phase1/flutter_increment_1/generate_geometry.py --reference-svg docs/ui_ux/premium_phase1/flutter_increment_1/reference_scene.svg
dart format lib/screens/dev/premium_scene/premium_scene_geometry.g.dart
```

`geometry_manifest.json` registra hashes, objetos y dimensiones. `reference_scene.svg` es la referencia normalizada para comparación; no sustituye los SVG originales. T4 sigue ausente y los tres trazados originales del isotipo conservan sus colores y proporciones.

## Evidencia visual

- `browser_scene.png`: referencia SVG renderizada a 620×430.
- `flutter_scene.png`: captura del `CustomPainter` nativo mediante prueba de widget, a la misma resolución.
- `visual_comparison.json`: diferencia numérica entre ambas imágenes. Las pequeñas diferencias de antialiasing no constituyen una medición de rendimiento Android.

Para regenerar la captura nativa:

```powershell
flutter test --no-pub --dart-define=URBES_EXPORT_SCENE=true -r expanded test/premium_scene_test.dart
```

Para inspeccionar en Flutter, usar `lib/main_dev.dart`, abrir el panel DEV y pulsar **Ver escena premium D (estática)**. El toque cierra la escena; la intro anterior continúa disponible. No instalar automáticamente sobre una app con datos reales: DEV comparte actualmente el identificador Android de producción.

## Límites

No se implementan el recorrido móvil del vehículo, flotación, impulso, transición a Login ni duración de 4,44 s. El automóvil está congelado en una pose; su futura animación debe partir de las piezas y trayectoria originales, no interpolar esta captura. La revisión en dispositivo, TalkBack y el perfilado de fotogramas/memoria permanecen pendientes.

## Extensión del Incremento 2 — vehículo aislado

Se conserva aquí la preparación de recursos para no duplicar infraestructura. La escena estática anterior permanece intacta; el modo adicional solo mueve el vehículo.

```powershell
node docs/ui_ux/premium_phase1/flutter_increment_1/generate_vehicle.mjs
dart format lib/screens/dev/premium_scene/premium_vehicle_geometry.g.dart
flutter test --no-pub --dart-define=URBES_EXPORT_VEHICLE=true -r expanded test/premium_vehicle_test.dart
```

`generate_vehicle.mjs` extrae las 42 piezas de `assets.js`, comprueba hashes contra v3 y prepara Dart sin dependencias nuevas. `vehicle_reference.json` contiene diez muestras calculadas por `vehicle.js` para contrastar posición, tangente, proyección, caras visibles y orden de profundidad. El orden se compara estabilizando empates coplanares a nueve decimales.

Las capturas `vehicle_0.png`, `vehicle_1400.png`, `vehicle_2160.png` y `vehicle_2600.png` muestran inicio, curva, referencia estática y destino. `vehicle_visual_comparison.json` contrasta 2160 ms con el Incremento 1. Son evidencias de prueba, no otra página HTML ni recursos de reproducción de la app.

En `main_dev.dart`, panel DEV: **Reproducir recorrido del vehículo D**. Pausa inicial de 600 ms y recorrido de 2000 ms; el auto se detiene al final y el toque cierra. Para repetir, volver a pulsar el mismo botón. El entorno y el isotipo no se animan. No se usan servicios reales ni se instala automáticamente en hardware.

## Extensión del Incremento 3 — construcción por capas

Mismo entorno DEV y recursos; acción adicional **Reproducir construcción por capas D**. El escenario aparece con los tiempos/pivotes del HTML y se completa a 955 ms; el auto conserva su recorrido 600–2600 ms, ahora con la entrada de opacidad 600–780 ms de D. El isotipo y su sombra permanecen estáticos. Se mantienen los modos anteriores para comparación.

```powershell
node docs/ui_ux/premium_phase1/flutter_increment_1/generate_scene_reference.mjs
flutter test --no-pub --dart-define=URBES_EXPORT_LAYERS=true -r expanded test/premium_scene_motion_test.dart
```

El generador evalúa las llamadas originales a `reveal` después de verificar el hash de `prototype.js`; `scene_reference.json` guarda doce instantes para pruebas. `layers_0.png`, `layers_380.png`, `layers_720.png`, `layers_955.png` y `layers_2160.png` documentan la construcción. `scene_visual_comparison.json` compara el estado completo con el Incremento 2. No son recursos nuevos para la app ni una nueva interfaz HTML. La tabla temporal completa está en la especificación SDD; flotación, reacción y Login quedan fuera de este incremento.

## Extensión del Incremento 4 — baliza flotante D

Acción **Reproducir baliza flotante D** en el panel existente. Isotipo/sombra entran 720–960 ms; elevación y retorno únicos de 2 px entre 960–2160 ms; estabilización hasta 2400; reacción de 3 px y onda hasta 2680 ms. Las unidades son las del artboard HTML: se convierten a la escena base conservando su escala. No se implementan vuelo hacia texto URBES ni Login. El modo anterior de capas permanece disponible.

```powershell
node docs/ui_ux/premium_phase1/flutter_increment_1/generate_beacon_reference.mjs
flutter test --no-pub --dart-define=URBES_EXPORT_BEACON=true -r expanded test/premium_beacon_test.dart
```

`beacon_reference.json` contiene 16 muestras de la función original `drawVariant`, con hashes de procedencia. Seis PNG `beacon_0/840/1560/2160/2540/2680.png` son evidencia nativa de las fases; no recursos de reproducción. `beacon_visual_comparison.json` comprueba que las regiones ajenas a la baliza conservan las capturas del Incremento 3. El painter reutiliza el logo preparado, sin modificar SVG ni duplicarlo visualmente. Ver especificación SDD para curvas, radios, alpha, sincronización por proximidad, resultados y límites.

## Selección de evidencias para el checkpoint 1–4

Los cuatro incrementos fueron aprobados por el usuario en Android. El checkpoint conserva la implementación, sus geometrías Dart, los cuatro generadores, los manifiestos/muestras usados por pruebas y las métricas de comparación. Sus fuentes Motion/v3 ya están versionadas en el historial.

Se versionan diez capturas propias representativas: `browser_scene.png`, `flutter_scene.png`, `vehicle_1400.png`, `vehicle_2600.png`, `layers_380.png`, `layers_720.png`, `beacon_0.png`, `beacon_840.png`, `beacon_1560.png` y `beacon_2540.png`.

Se conservan **solo en disco**, sin eliminar ni cambiar `.gitignore`: `vehicle_0.png`, `vehicle_2160.png`, `layers_0.png`, `layers_955.png`, `layers_2160.png`, `beacon_2160.png` y `beacon_2680.png`. Son capturas adicionales regenerables con los comandos de exportación de pruebas anteriores; los estados completos próximos a 2160 ms resultan visualmente redundantes con la referencia estática. Las métricas históricas pueden referirse a esas capturas locales: para reconstruirlas, ejecutar la prueba correspondiente con su define `URBES_EXPORT_*`.

Las capturas PNG no son necesarias para compilar ni para ejecutar las pruebas sin exportación. Las muestras JSON sí se incluyen porque las pruebas las leen. El checkpoint excluye APK, cachés, configuración sensible y referencias externas; no contiene implementación del cierre de marca ni transición a Login.

## Extensión del Incremento 5 — cierre de marca DEV

Acción **Reproducir cierre de marca D** en el panel existente. Se usa el artboard de teléfono 390×844, con el mismo dibujo y las fases aprobadas. El texto URBES entra 1900–2200 ms; vuelo 2680–3360; reposo hasta 3540; entrega conjunta a cabecera y desplazamiento de escena hasta 4090; fin a 4440 ms. La app debajo conserva su sesión/ruta; el destino solo muestra una etiqueta DEV, sin formulario ni autenticación.

```powershell
python docs/ui_ux/premium_phase1/flutter_increment_1/generate_wordmark.py
dart format lib/screens/dev/premium_scene/premium_wordmark.g.dart
node docs/ui_ux/premium_phase1/flutter_increment_1/generate_closure_reference.mjs
node docs/ui_ux/premium_phase1/flutter_increment_1/export_closure_browser.mjs
flutter test --no-pub --dart-define=URBES_EXPORT_CLOSURE=true -r expanded test/premium_closure_test.dart
```

La generación de contornos requiere fontTools, ya disponible en el entorno de autoría; no es dependencia Flutter ni se instala como parte de este incremento. Se deriva únicamente URBES a tamaño 32/peso 800 del Manrope local con OFL y FONTLOG existentes. `wordmark_manifest.json` registra hash, glifos, peso y avance. El original de fuente/logo queda intacto y `pubspec.yaml` no cambia.

`closure_reference.json` contiene quince estados de la coreografía JS original. Cuatro parejas `closure_browser_*.png` / `closure_flutter_*.png` (3100, 3450, 3800, 4440 ms) comparan vuelo, reunión, entrega y cabecera. El script de browser abre el HTML original con un perfil temporal aislado, sin controles nuevos, y oculta únicamente su formulario para esta comparación. Las capturas nativas excluyen la etiqueta de revisión para comparar la misma región. `closure_browser_metrics.json` y `closure_visual_comparison.json` registran encuadre/métricas. El usuario aprobó el Incremento 5 en Android físico y autorizó su checkpoint local con estas evidencias propias; el perfilado sigue pendiente y no se implementa el formulario del Incremento 6.

## Extensión del Incremento 6 — Login real DEV

Acción **Reproducir Splash → Login real DEV** en el mismo panel. Reutiliza la escena/cierre y los campos, validadores, botón y envío de `LoginScreen`, mediante un constructor opcional de presentación. La sesión de la revisión es un mock local separado de la sesión/router de la app. No altera Firebase, navegación ni la presentación por defecto del Login.

Título 4090–4330 ms, campos 4130–4370, botón 4170–4410: opacidad y desplazamiento 6→0 px, curva cúbica de salida, reloj único D. Omisión/movimiento reducido llevan directamente al formulario; emergencia/segundo plano retiran la revisión. El scroll común admite teclado y texto grande sin cambiar la escala de la ilustración.

```powershell
flutter test --no-pub -r expanded test/premium_login_test.dart
flutter test --no-pub --dart-define=URBES_EXPORT_LOGIN=true -r expanded test/premium_login_test.dart
```

La segunda orden genera únicamente `login_flutter_4440.png`, evidencia propia opcional con Manrope local. No se incorpora fuente ni dependencia nueva a Flutter. Ver la especificación SDD para aislamiento, validación, diferencias Material/HTML e instrucciones de revisión física. Los recursos originales y las capturas locales anteriores permanecen intactos.
