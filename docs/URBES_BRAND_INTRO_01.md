# URBES Brand Intro 01 — Animated Brand Splash

**Estado:** variante visual experimental en DEV. El escudo y el logotipo vectorial son provisionales hasta la aprobación de identidad. Esta tarea no cierra las decisiones globales D1–D3 de `UI_UX_PHASE1_SPEC.md` ni modifica la arquitectura funcional del plan.

## Concepto y ejecución

El primer fotograma Flutter reproduce el recurso nativo estático: fondo `#F8F9FA`, dos bordes de carretera navy `#1B2B48` y tres marcas centrales. Así, Android muestra una escena de marca durante la carga del motor y Flutter continúa desde la misma geometría. La secuencia inicial comienza cuando Flutter confirma que rasterizó su primer fotograma; la reproducción manual DEV empieza de inmediato. El objetivo es que el trabajo del arranque no consuma los 1900 ms de movimiento antes de que pueda verse. El router y los proveedores se inicializan sin una espera añadida. [Referencia de Flutter para el launch screen Android](https://docs.flutter.dev/platform-integration/android/splash-screen); [señal de primer fotograma rasterizado](https://api.flutter.dev/flutter/widgets/WidgetsBinding/waitUntilFirstFrameRasterized.html).

La carretera extiende sus extremos; una silueta superior de vehículo la recorre; las dos trayectorias Bézier se interpolan hasta encontrarse como contorno de escudo; cuatro nodos conectados aparecen en el interior; «URBES» se dibuja con trazos vectoriales propios. El símbolo no usa imágenes rasterizadas, brillo, rebote ni animación continua. La composición se inspeccionó localmente a 360 × 780 dp mediante capturas temporales, que no forman parte del repositorio. La evaluación del movimiento requiere la ejecución en el Motorola.

| Etapa | Ventana dentro de 1900 ms | Curva |
| --- | --- | --- |
| Extensión de carretera | 0–23 % | `easeInOutCubic` |
| Aparición y recorrido del vehículo | 14–48 %; se retira entre 54–72 % | `easeInOutCubic` |
| Interpolación de carretera a escudo | 42–72 % | `easeInOutCubic` |
| Conexiones internas | 58–79 % | `easeInOutCubic` |
| Trazado secuencial de URBES | 69–82 % | `easeInOutCubic` |
| Salida sobre la pantalla ya construida | 88–100 % | `easeInOutCubic` |

`CustomPainter(repaint: progress)` actualiza únicamente pintura en cada fotograma, sin reconstruir el router. La escena usa un `Ticker` y un `ValueNotifier<double>`; cada avance se limita a 40 ms, de modo que un fotograma demorado no salta directamente al escudo final. Los 1900 ms son tiempo de movimiento efectivo: si el teléfono se detiene durante un fotograma, la duración real puede crecer. El ticker y el notifier se liberan en `dispose`; la escena se cierra al terminar, al tocarla, al salir a segundo plano, al activarse movimiento reducido o al llegar un incidente crítico. El evento crítico se observa directamente desde `EventProvider`: el overlay desaparece en la misma actualización, sin esperar el final de la animación. La ruta de emergencia sigue bajo control de `go_router`. TalkBack recibe una única acción para omitir la intro y no recorre los controles ocultos bajo ella.

## Ajuste tras la prueba de arranque en Moto G9 Power

El usuario observó tres comportamientos repetibles: reproducción manual DEV fluida; reapertura tras cerrar la app con carretera inicial algo más larga pero secuencia completa; y primer inicio tras borrar datos con carretera estática, escudo casi instantáneo y salida rápida. El registro compartido de ese último caso señaló 105 fotogramas omitidos y una pausa aproximada de 1,8 s. Esto demuestra una demora de arranque en esa ejecución, pero no identifica todavía si el coste dominante fue plataforma, UI de Flutter o rasterización. La espera del primer fotograma y el avance acotado corrigen el salto temporal de la animación Flutter; no hacen que Android o Flutter puedan dibujar mientras el hilo necesario esté detenido. Tampoco eliminan el tiempo estático propio del splash nativo en un arranque frío. La causa y la fluidez en hardware deben comprobarse con una nueva traza profile.

Flutter nativo es suficiente para estas trayectorias precisas, el logotipo provisional y el control del ciclo de vida. Rive exigiría runtime, artefacto `.riv` y flujo de edición nuevos; aportaría más si se aprobara una marca con deformaciones o estados mucho más complejos. No se añade ninguna dependencia. [Referencia de `CustomPainter` y repintado](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html); [runtime de Rive](https://rive.app/docs/runtimes/flutter/flutter).

## Alcance de archivos

| Archivos | Propósito |
| --- | --- |
| `lib/screens/dev/brand_intro/dev_brand_intro.dart` | Control DEV, host de una sola ejecución por arranque, painter vectorial y salida prioritaria. |
| `lib/main_dev.dart` | Instala el controlador y host con repositorios simulados. |
| `lib/screens/dev/dev_simulator_screen.dart` | Botón “Reproducir intro URBES”; se deshabilita si hay emergencia crítica. |
| `lib/app.dart` | Punto `devBuilder` opcional en `MaterialApp.router`; `main.dart` usa el valor nulo y mantiene el arranque habitual. |
| `android/app/src/debug/res/` y `android/app/src/profile/res/` | Vector estático, fondo y colores de launch; `values-v31` declara la presentación del sistema Android 12+. Release conserva los recursos de `src/main`. |
| `test/brand_intro_test.dart` | Ciclo, finalización, reproducción, navegación, movimiento reducido, segundo plano y prioridad crítica. |

El recurso nativo se duplica intencionadamente entre `debug` y `profile` para evitar cambiar `release` o introducir variantes de Gradle. Android 12+ puede aplicar máscara o escala propia al icono del splash del sistema; la coincidencia exacta del traspaso debe comprobarse en un dispositivo de esa versión. Para el Moto G9 Power objetivo, también queda pendiente comprobar la versión Android concreta.

## Validación

**Completado en el ajuste de arranque:** 29/29 pruebas Flutter dirigidas con mocks entre `brand_intro_test.dart`, `dev_simulator_test.dart`, `emergency_flow_test.dart`, `motion_pilot_test.dart` y `widget_test.dart`. Dos pruebas nuevas simulan una pausa de 1,8 s y una señal tardía del primer fotograma. El análisis estático de `dev_brand_intro.dart` y `brand_intro_test.dart` no reportó problemas; ambos archivos quedaron formateados. `flutter build apk --profile --no-pub -t lib/main_dev.dart` generó el APK actualizado en `build/app/outputs/flutter-apk/app-profile.apk` (73,7 MB). Las comprobaciones previas de XML y composición PNG siguen vigentes, pero no miden fluidez ni traspaso nativo en el teléfono.

## Prueba en Motorola Moto G9 Power

**Condiciones:** SDA apagado; bridge detenido; Firebase real sin utilizar; no se necesita Firebase Emulator. Celular encendido, depuración USB activa y app DEV en modo profile. Internet puede ser necesario para herramientas Android/Flutter ya existentes, pero los datos y la sesión DEV son simulados. No usar credenciales reales.

**Antes de instalar:** `main_dev.dart` y `main.dart` usan por ahora el mismo `applicationId` Android. `flutter run` puede reemplazar una instalación normal ya presente en el Motorola. Si tienes esa instalación o datos locales que debas conservar, usa un emulador o un equipo de prueba libre de esa app hasta crear una variante Android con identificador distinto. No desinstales la app real solo para esta evaluación.

```powershell
flutter devices
flutter run --profile --no-pub -t lib/main_dev.dart -d <ID_MOTOROLA>
```

Sustituye el marcador por el ID que muestra Flutter y no lo copies a documentación compartida. Observa la continuidad entre el recurso nativo y el primer fotograma Flutter al arrancar. Para volver a ver la animación sin reinstalar: botón de herramientas DEV → **Reproducir intro URBES**. Toca la escena para omitirla; comprueba que la pantalla previa permanece donde estaba. Repite con “Quitar animaciones” de Android: la escena debe omitirse. Comprueba TalkBack y el retorno desde segundo plano. Desde DEV, simula un SOS y confirma que la pantalla crítica aparece sin esperar la intro. Usa DevTools en modo profile para registrar tiempos de UI y raster, fotogramas fuera del presupuesto de la frecuencia real del dispositivo, memoria y una captura del traspaso nativo–Flutter.

La evaluación en hardware físico y el perfilado real requieren autorización separada según `AGENTS.md`; estas son instrucciones para el usuario, no una afirmación de pruebas ya ejecutadas. No se declaran 60 FPS estables.
