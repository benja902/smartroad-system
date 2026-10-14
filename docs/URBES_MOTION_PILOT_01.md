# URBES Motion Pilot 01 ? Entrada y pantalla Inicio

Piloto local experimental del 12 de octubre de 2026, autorizado exclusivamente para login, presentaci?n inicial de Inicio y microinteracciones relacionadas. Pendiente de evaluaci?n visual en Android y perfilado f?sico. No constituye un patr?n aprobado para otros m?dulos ni cierra tareas funcionales del plan.

## Dise?o y comportamiento

Se conservan Manrope, AppColors, espaciado, radios, tarjetas y textos funcionales. No se agregan dependencias. La autorizaci?n de este piloto delimita la implementaci?n frente a las decisiones generales pendientes de UI_UX_PHASE1_SPEC.md; no se modifica ese documento previo.

| Contexto | Movimiento | Duraci?n y curva |
| --- | --- | --- |
| Login | Contenido desde 8 dp hacia abajo a su posici?n final; opacidad 0,85 ? 1. Campos, validaci?n y bot?n disponibles desde el inicio. | 240 ms, `Curves.easeOutCubic`. |
| Inicio: bienvenida | Mismo desplazamiento y opacidad. Cabecera estable. | 0?240 ms, `easeOutCubic`. |
| Inicio: estado URBES | Desplazamiento de 8 dp, opacidad completa. | 36?240 ms, `Interval(0.15, 1, curve: easeOutCubic)`. |
| Inicio: indicadores y veh?culo | Desplazamiento de 8 dp, opacidad completa. | 60?240 ms, `Interval(0.25, 1, curve: easeOutCubic)`. |
| Barra inferior | Indicador Material, icono seleccionado y etiqueta enfatizada. Cambio de rama inmediato. | 180 ms; curvas internas nativas de `NavigationBar`, sin una curva personalizada adicional. |
| Accesos r?pidos | Tinta Material visible en pulsaci?n/foco/hover; callback inmediato. | Tiempos nativos de `InkWell`, sin secuencia ni espera a?adida. |

Una sola l?nea temporal por pantalla montada, con controlador liberado en `dispose`. Los fotogramas reconstruyen las envolturas de presentaci?n mediante `AnimatedBuilder.child`, sin reconstruir los datos de las tarjetas. Los cambios de Provider, teclado o estado del formulario no reinician el movimiento. Las secciones creadas despu?s del final de la l?nea temporal aparecen en su posici?n definitiva.

Inicio conservado por `StatefulShellRoute.indexedStack` no repite la entrada al cambiar de pesta?a ni al volver de una ruta superpuesta; una instancia nueva s? la ejecuta. El scroll de la rama se conserva. No hay animaci?n global, splash obligatorio, temporizadores nuevos ni cambios de redirecci?n.

Con `MediaQuery.disableAnimationsOf(context)`, la entrada termina inmediatamente y la selecci?n dura cero. Activar esta preferencia durante la entrada tambi?n la termina; desactivarla no la repite. La retroalimentaci?n t?ctil/foco Material se mantiene.

El banner de atenci?n, el mapa, las acciones y el historial reciente no participan en la secuencia de entrada. La emergencia conserva su flujo y transici?n existentes; una prueba inyecta SOS mientras Inicio sigue entrando y comprueba que se muestra sin esperar esos 240 ms.

## Archivos y reutilizaci?n

| Archivo | Cambio |
| --- | --- |
| `lib/widgets/screen_entrance.dart` | Nuevos `ScreenEntrance` y `EntranceSection`: l?nea temporal finita compartida por login e Inicio; evita controladores repetidos por tarjeta. |
| `lib/screens/auth/login_screen.dart` | Envuelve el formulario existente; conserva autenticaci?n, validadores, campos y `PrimaryButton`. |
| `lib/screens/home/home_screen.dart` | Coordina bienvenida, estado, indicadores y veh?culo reutilizando todas las tarjetas. |
| `lib/navigation/main_shell.dart` | Sustituye la barra por `NavigationBar` nativa; conserva cinco destinos y el mismo `goBranch` con `initialLocation`. |
| `lib/core/theme/app_theme.dart` | Estilo de la barra con tokens y Manrope existentes. |
| `lib/screens/home/widgets/quick_actions_row.dart` | Tinta visible mediante `Ink`, estados de interacci?n y etiquetas completas; apilado en ancho reducido o texto grande. Subt?tulo usa token de 12 dp en vez de 10 dp. |
| `lib/screens/home/widgets/device_indicators_grid.dart` | Indicadores sin truncado y una columna con texto grande. |
| `lib/screens/home/widgets/vehicle_summary_card.dart` | Activa el ajuste multil?nea de la etiqueta SDA en Inicio. |
| `lib/widgets/status_pill.dart` | Opci?n `wrapLabel`, desactivada por defecto; solo Inicio la activa para evitar desborde con texto ampliado. |
| `test/motion_pilot_test.dart` | Pruebas del ciclo de entrada, accesibilidad, formulario, navegaci?n y emergencia durante el movimiento. |
| `docs/URBES_MOTION_PILOT_01.md` | Alcance, decisiones, evidencia y recorrido Android. |

## Validaci?n local

**Completado:** formato de los diez archivos Dart; an?lisis dirigido de esos diez archivos sin problemas; **21/21 pruebas aprobadas** (7 nuevas del piloto, 1 de arranque, 6 de emergencia y 7 del simulador DEV). `git diff --check` sin errores de espacios. Pruebas exclusivamente con repositorios mock, sin inicializar Firebase, SDA ni bridge.

**Bloqueos actuales:** ninguno en la validaci?n local dirigida. **Pendiente:** compilaci?n/ejecuci?n Android y evaluaci?n f?sica en profile, revisi?n visual y TalkBack. No se ejecut? la suite completa del repositorio.

Referencias t?cnicas verificadas: [duraci?n de NavigationBar](https://api.flutter.dev/flutter/material/NavigationBar/animationDuration.html) y [preferencia disableAnimationsOf](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html).

Comandos reproducibles:

```powershell
dart format lib/widgets/screen_entrance.dart lib/widgets/status_pill.dart lib/screens/auth/login_screen.dart lib/screens/home/home_screen.dart lib/screens/home/widgets/quick_actions_row.dart lib/screens/home/widgets/device_indicators_grid.dart lib/screens/home/widgets/vehicle_summary_card.dart lib/navigation/main_shell.dart lib/core/theme/app_theme.dart test/motion_pilot_test.dart
flutter analyze --no-pub lib/widgets/screen_entrance.dart lib/widgets/status_pill.dart lib/screens/auth/login_screen.dart lib/screens/home/home_screen.dart lib/screens/home/widgets/quick_actions_row.dart lib/screens/home/widgets/device_indicators_grid.dart lib/screens/home/widgets/vehicle_summary_card.dart lib/navigation/main_shell.dart lib/core/theme/app_theme.dart test/motion_pilot_test.dart
flutter test --no-pub -r expanded test/motion_pilot_test.dart test/widget_test.dart test/emergency_flow_test.dart test/dev_simulator_test.dart
```

La primera ejecuci?n del formateador escribi? los cambios, pero termin? con error por acceso al archivo de telemetr?a fuera del workspace. Se repiti? con acceso local autorizado al SDK. En pruebas se ajust? la espera de entrega del stream mock y el recorrido de scroll; la prueba de texto al 200 % detect? y motiv? el ajuste de la etiqueta SDA.

## Recorrido de prueba en tu Android

Estado requerido: SDA apagado, bridge detenido, Firebase real sin utilizar (no hace falta desactivar el proyecto), Emulator Firebase apagado. Celular encendido y conectado por USB con depuraci?n USB habilitada; ejecutar ?nicamente la app DEV. Internet puede hacer falta para herramientas y la descarga inicial de Manrope por la configuraci?n existente de google_fonts; los datos y la autenticaci?n DEV no lo necesitan.

Desde `D:\smartroad`, el usuario puede ejecutar:

```powershell
flutter devices
flutter run --profile -t lib/main_dev.dart -d <ID_ANDROID>
```

Sustituir `<ID_ANDROID>` por el identificador local mostrado por Flutter, sin incorporarlo a documentaci?n o logs compartidos. Estos comandos son instrucciones para el usuario; el agente no us? hardware f?sico ni instal? una APK.

1. DEV abre una sesi?n simulada autom?ticamente. Observar la primera entrada de Inicio, desplazar el contenido y probar los cinco destinos de la barra. Al volver, comprobar que se conserva el scroll y no se repite la entrada.
2. Ir a Perfil ? Cerrar sesi?n. Observar el login. Tocar Iniciar sesi?n vac?o para comprobar validadores; abrir el teclado y comprobar que se puede alcanzar el bot?n desplazando el formulario.
3. Usar exclusivamente valores ficticios: `pilot@example.invalid` y cualquier texto de prueba no vac?o. El mock acepta ambos; no usar credenciales reales. Iniciar sesi?n y observar Inicio. Para repetir ambas entradas, cerrar sesi?n otra vez.
4. En Inicio, pulsar accesos r?pidos y volver con Atr?s. Comprobar tinta inmediata, texto completo y destino existente. ?Ver mapa? mantiene su callback pendiente; no constituye una funci?n nueva.
5. Abrir el bot?n de herramientas DEV, cambiar ?Dispositivo offline? y volver. Comprobar que el estado cambia sin repetir la entrada de Inicio.
6. En el panel DEV, disparar ?SOS? o ?Choque grave?. Comprobar que aparece la emergencia existente; reconocerla con ?Ya lo vi? para regresar. Todo es simulado.
7. Activar ?Quitar animaciones? o la opci?n equivalente de accesibilidad Android. Cerrar sesi?n y entrar de nuevo; la entrada y la selecci?n inferior deben ser inmediatas. Repetir con texto/tama?o de pantalla m?ximos y TalkBack. El nombre de la opci?n depende del fabricante.
8. Para medir, abrir DevTools desde la sesi?n `flutter run --profile`, registrar UI/raster durante entrada, scroll, selecci?n y actualizaciones simuladas. Anotar modelo de dispositivo, Android y frecuencia de pantalla, sin identificadores privados. Evaluar contra el presupuesto correspondiente a esa frecuencia.

## Riesgos y pendientes

- Evaluaci?n visual en celular, TalkBack real, orientaci?n y escalado m?ximo espec?fico del dispositivo, contraste global y perfilado UI/raster pendientes. Las pruebas a 320 ? 640 dp y texto 200 % no sustituyen esas verificaciones. No se afirman 60 FPS estables.
- `NavigationBar` Material tiene una altura y un indicador diferentes a la barra anterior; evaluar en el celular si el espacio ocupado es adecuado.
- El pulso preexistente de `AttentionBanner` no forma parte de este piloto ni de la garant?a de movimiento reducido de las animaciones nuevas.
- Los textos sobre operaci?n/frescura, el mapa pendiente, los roles y los flujos funcionales mantienen sus limitaciones previas. No se han corregido pol?ticas ni m?dulos pendientes.
- Sin cambios en Firebase, repositorios, reglas, bridge, firmware o arranque nativo; sin commit ni push.
