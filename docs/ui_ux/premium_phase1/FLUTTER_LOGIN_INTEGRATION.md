# Integración compartida Splash→Login — Flutter DEV

17 de octubre de 2026. Integración autorizada para revisión. No aprueba Design System v1.0 ni activa automáticamente el Splash premium en producción. Referencia previa: checkpoint `1b5a9de`, propuesta documental; `98f5689`, Incremento 6 aprobado. Sin nuevos commits ni push.

## Auditoría previa

- `main.dart` inicializa Firebase y crea `UrbesApp` con repositorios reales. No instalaba `DevBrandIntroHost` ni se modifica en esta tarea.
- `main_dev.dart` inyectaba mocks, `DevBrandIntroController` y `DevBrandIntroHost` mediante el builder de MaterialApp, por encima del router. El mock comenzaba con una sesión activa y el arranque mostraba la intro DEV anterior.
- `AppRouter` crea `LoginScreen` en `/login`. `SessionProvider.isSignedIn` depende del stream del repositorio. La sesión abre Inicio; sin sesión solo se permiten Login/Registro. La prioridad crítica se aplica a sesiones autenticadas. No se cambia esta política ni ninguna ruta.
- `DevPremiumLoginPreview` mostraba un `LoginScreen` con constructor visual opcional y sesión mock local. El Login habitual mantenía otro diseño. Eso exigía sincronizar manualmente dos presentaciones.
- La geometría, painters y modelos deterministas eran reutilizables, pero su biblioteca importaba Login y mocks por un `part`. Se separa esa dependencia.

## Arquitectura resultante

```text
main.dart (sin cambios) → UrbesApp → router existente → LoginScreen
                                                     → presentación premium final estática

main_dev.dart → mocks existentes sin sesión inicial → UrbesApp / mismo router
             → DevBrandIntroHost / reloj D → PremiumLoginTimeline
                                            → mismo LoginScreen / formulario real

panel DEV → reproducción de revisión → wrapper DEV con mock local aislado
                                      → mismo LoginScreen / misma presentación
```

`LoginScreen` conserva el único formulario funcional, controladores, validadores, autofill, envío y mapeo de errores. La API opcional de presentación se conserva para compatibilidad y pruebas; el Login habitual y la revisión del panel usan ambos la misma presentación predeterminada. Se elimina el diseño anterior de escudo/campos centrados como segunda composición mantenida.

`PremiumLoginPresentation` dispone la ilustración, marca, scroll, tema local y región del formulario. `PremiumLoginForm` presenta los widgets reales de `LoginFormParts`; no autentica ni mantiene copias de sus controladores. `PremiumLoginTimeline` solo transporta señales visuales y slots de revisión. Ninguno de estos componentes compartidos importa mocks, Firebase o router.

Los recursos nativos y modelos pasan de `lib/screens/dev/premium_scene/` a `lib/presentation/premium_scene/`. Geometrías, trayectoria, orientación, tiempos, ondas y contornos permanecen iguales; se actualizan imports y destinos de los dos generadores. No se regeneran ni duplican assets. Los helpers visuales anteriores de comparación siguen disponibles para el panel.

`lib/screens/dev/premium_login_preview.dart` contiene únicamente el aislamiento de sesión mock, Overlay para selección de texto y controles de revisión. Ya no contiene otro diseño de formulario. `DevBrandIntroHost` sigue siendo el único reproductor de D en DEV; el modo de ruta reutiliza su reloj y notificaciones en lugar de crear un segundo reproductor.

## Flujo habitual DEV y garantías

`main_dev.dart` usa `MockAuthRepository.signOut()` antes de crear los proveedores. No modifica el repositorio: únicamente inicia este entorno sin sesión. GoRouter presenta `/login` por su regla existente. El host entrega el reloj D al Login de la ruta, sin overlay que duplique marca, ilustración o formulario. El panel no es necesario para ver esta entrada.

En el arranque inicial animado, el formulario se monta desde 4090 ms. Título 4090–4330, campos 4130–4370 y botón 4170–4410, con el reloj compartido que termina a 4440. Conserva la entrada cúbica de salida y escala final 1.0. El host detiene decoración al autenticarse; el router abre Inicio o la emergencia correspondiente sin esperar un segundo Splash. Al cerrar sesión desde Perfil, se presenta directamente el Login premium con el reloj estático final; el cambio de sesión no reproduce D.

Omitir/movimiento reducido llevan directamente al destino. Segundo plano completa la decoración de la ruta sin destruir el Login o sus campos; al volver no se reproduce. En el modo de revisión aislada del panel, segundo plano sigue cerrando el overlay, como antes. Los incidentes disponibles interrumpen la decoración; **EventProvider no consulta incidentes sin sesión**, por lo que no se inventa una escucha pública. Un incidente almacenado mientras no hay sesión se resuelve al autenticar y abre la pantalla crítica conforme al router original. Las pruebas distinguen ese caso de la interrupción del overlay con sesión activa.

La contraseña sigue oculta, tal como estaba implementada en Flutter; no se incorpora aún un ojo funcional. Su propuesta HTML y los futuros cambios de iconos/espacio/color pertenecen al refinamiento posterior. No se cambian validadores, políticas de error, proveedor de Auth ni credenciales. El tema premium del Login es local y no aprueba/modifica el Design System global.

## Revisión con Edge y Hot Reload

Desde la raíz:

```powershell
flutter run -d edge -t lib/main_dev.dart --no-pub
```

DEV comienza en la secuencia D y llega al Login real. Usar solo un correo ficticio como `pilot@example.invalid` y contraseña ficticia no vacía. El mock acepta el envío; la sesión de la aplicación se inicia y aparece Inicio. Perfil → Cerrar sesión retorna directamente al Login premium final, sin repetir D. El panel mantiene todos los modos anteriores y **Reproducir Splash → Login real DEV**, que continúa siendo una revisión aislada y no cambia la sesión global. Para repetir el arranque sin sesión, reiniciar DEV; Hot Reload no debe confundirse con un arranque nuevo.

Editar `premium_login_form.dart`, `premium_login_presentation.dart` o las decoraciones de los campos en `login_screen.dart` refina la misma implementación. `r` en la terminal de Flutter aplica Hot Reload; `R` reinicia DEV, que vuelve a iniciar sin sesión mock. Tras cambiar la estructura/imports de esta integración es necesario un reinicio inicial; los cambios visuales siguientes se revisan con Hot Reload. No editar los generados para ajustar el formulario.

SDA apagado, bridge detenido y sin Firebase real. No hace falta dispositivo Android. La tipografía global existente usa Google Fonts: no se cambia su política de carga; el caché/conectividad de fuentes debe distinguirse de los datos mock locales.

## Límite de producción

La ruta habitual ya reutiliza la presentación premium estática, como autorizó esta tarea. `main.dart`, GoRouter, `SessionProvider`, repositorios, Firebase y dependencias se conservan. No se instala un host de reproducción en producción ni se añade ruta de Splash. Activar D automáticamente en producción, perfilar en Android físico y aplicar el Design System global requieren autorización posterior. Esta integración se detiene para revisión humana; no inicia el refinamiento adicional del formulario.

## Validación de la integración

### Corrección de regresión: logout no es arranque

La auditoría encontró `main` en `1b5a9de`, con la integración compartida aún sin commit. Ese checkpoint conserva el comportamiento correcto; el último cambio versionado del host era `98f5689`. En la arquitectura anterior el host solo recibía el disparo inicial y revisiones del panel, sin observar cierres de sesión. No existía una condición funcional explícita «no animar en logout»: la separación de responsabilidades conservaba ese comportamiento.

La integración agregó `_onSessionChanged()` y la rama `!isSignedIn && !_routeLogin → _startRouteLogin()`. Tras autenticar, `_routeLogin` quedaba falso; el posterior logout cumplía esa condición y reiniciaba D a cero. Ni `SessionProvider`, GoRouter, `PremiumLoginPresentation` ni `LoginScreen` pedían esa repetición. La corrección mínima elimina esa rama: el listener solo finaliza la decoración al autenticar; el disparo inicial permanece en `didChangeDependencies` y la reproducción manual en el controlador del panel. No se añade una nueva política de autenticación ni un flag de «Splash consumido».

La prueba nueva del recorrido real Perfil → Cerrar sesión falló antes del cambio, observando `ValueNotifier(0.0)` donde debía existir el reloj final estático. El helper anterior iniciaba la prueba de arranque cerrando una sesión activa y enmascaraba la diferencia; se reemplaza por una composición DEV realmente sin sesión desde su creación. La prueba de regresión comprueba además reautenticación y reproducción manual del panel, sin cambiar el mock ni el router. Las seis pruebas de ruta pasan después de la corrección.

Validación posterior: **80/80 pruebas dirigidas satisfactorias**, análisis estático del host y pruebas de ruta sin incidencias, `git diff --check` correcto. En esta corrección solo se editan el listener del host DEV, las pruebas de ruta y esta documentación; el resto del trabajo pendiente de integración permanece intacto. Sin commits, push, ejecución de hardware o refinamiento visual. Para verificar en Edge, reiniciar la ejecución DEV una vez y distinguir ese arranque del posterior logout desde Perfil; no se considera verificado Edge por las pruebas VM.

### Evidencia previa y cobertura de integración

- **79/79 pruebas dirigidas satisfactorias:** las 74 anteriores y cinco nuevas en `premium_login_route_test.dart`. Cubren ruta real y presentación estática sin host, sesión global frente al mock aislado, montaje temporal del formulario, omisión/segundo plano sin pérdida de campos, movimiento reducido y llegada a emergencia tras autenticar. Las pruebas del panel conservan interrupción crítica con sesión activa.
- **Análisis estático de 12 objetivos: cero incidencias.** `_submit`, `_messageFor`, campos, validadores y autofill se compararon con el checkpoint y permanecen iguales ignorando solo formato.
- Los nueve archivos trasladados de geometría/modelos/painters/contornos coinciden con el checkpoint al normalizar finales de línea Git. `premium_scene.dart` solo separa imports/part de la revisión DEV. No se modifican recursos originales del HTML ni las muestras de referencia.
- La exportación de QA volvió a pasar **9/9 pruebas** y la captura final del Login compartido es **idéntica byte a byte** a `login_flutter_4440.png` del checkpoint aprobado. Se conserva ese archivo sin cambios ni capturas redundantes.
- No se cambia `main.dart`, router, repositorios, proveedores de estado ni manifiestos de dependencias. No se usan Firebase real ni hardware.
- **Edge/Hot Reload pendiente de verificación efectiva:** se intentó `flutter run` local con Edge (headless y normal). En PowerShell no llegó a informar compilación; desde `cmd` alcanzó `<- compile org-dartlang-app:///web_entrypoint.dart`, pero no produjo más salida durante 60 segundos. Cada intento se interrumpió conforme a `AGENTS.md`. No se obtuvo confirmación de arranque web ni de Hot Reload, ni se atribuye la detención a un fallo de la app sin evidencia. Las pruebas VM y el análisis no sustituyen esa comprobación web. No se repite compilación Android costosa en esta integración.

```powershell
flutter test --no-pub -r expanded test/premium_login_route_test.dart test/premium_login_test.dart test/premium_closure_test.dart test/premium_beacon_test.dart test/premium_scene_motion_test.dart test/premium_vehicle_test.dart test/premium_scene_test.dart test/brand_intro_test.dart test/dev_simulator_test.dart test/emergency_flow_test.dart test/motion_pilot_test.dart test/widget_test.dart
```
