# Incremento B — cuatro destinos DEV y Perfil en cabecera

Estado: Incremento B conservado en el checkpoint local `d700c31` (`feat(ui): incorpora cuatro destinos y Perfil en cabeceras DEV`, 17 archivos). Ajuste posterior de cabeceras persistentes pendiente de revisión humana y sin segundo commit. No consolida MAIN ni realiza push.

## Estructura

| Entorno | Pill Active | Perfil |
| --- | --- | --- |
| DEV (`includeDevRoute: true`) | Inicio, Alertas, Vehículo, Historial | `/profile` es ruta externa al shell, abierta con `push` desde las cuatro cabeceras. La pantalla Perfil existente y su cierre de sesión se reutilizan. |
| MAIN | Inicio, Alertas, Vehículo, Historial, Perfil | Conserva la quinta rama y su comportamiento anterior. Sin nuevos controles DEV. |

Se reutiliza la configuración `includeDevRoute` y el `DevModeFlag` existentes: no hay otro router ni un nuevo modo de sesión. Las cuatro primeras ramas conservan su orden, identidad y navegadores con `StatefulShellRoute.indexedStack`. Los índices visibles DEV son 0–3; MAIN conserva 0–4. MainShell suministra la lista correspondiente al mismo componente de navegación, que ya calcula ancho, indicador y dirección a partir de la longitud de la lista. Las alternativas Actual y Underline permanecen en el selector DEV y utilizan los mismos cuatro destinos.

Perfil se abre sobre la pila raíz en DEV; al volver mediante el botón Atrás o el gesto/botón del sistema se descubre el shell que permaneció montado, en la pestaña de origen. No se navega forzosamente a Inicio para volver, no se guardan índices duplicados y no se modifica la autenticación. En Perfil no se muestra la barra inferior DEV, pues no es una quinta pestaña.

## Componente y preservación visual

`lib/widgets/profile_header_action.dart` centraliza el botón circular, colores, tooltip «Perfil», área mínima de 48 × 48 y feedback/foco Material. Recibe el callback; no conoce sesión ni datos. Diseño 1 lo usa en el mismo lugar, con el mismo tamaño y colores del botón previo. Su cabecera cartográfica, hero Navy, `auto.webp`, estudio, Bento, posición y actividad no se rediseñan. Las variantes anteriores de Inicio también conservan acceso a Perfil en DEV.

Alertas reutiliza su fila de cabecera, reemplazando el icono derecho en DEV. Vehículo e Historial añaden el botón a sus AppBar existentes: no se añade otra cabecera ni se implementan sus funcionalidades pendientes. Se corrige únicamente en DEV el ajuste de la fila existente de título/fecha de Alertas con `Wrap`, tras detectar un desbordamiento con texto al 200 %. No cambian los textos, datos, clasificación ni acciones. MAIN conserva la fila anterior.

Las reglas de redirect por sesión y prioridad crítica no cambian. No hay cambios en Firebase, Providers, repositorios, Login Signature v2, geometría/tiempos de D, `main.dart`, `main_dev.dart`, assets o dependencias.

## Validación dirigida

Las pruebas cubren cuatro destinos, Perfil desde cada pestaña, ruta conservada, regreso al origen sin reconstruir shell, actualización de disponibilidad con Perfil abierto, conservación de scroll de Inicio entre ramas, emergencia crítica desde Perfil y cierre de sesión sin repetir D. Se verifican también MAIN con cinco destinos, teclado, retorno del sistema, selección rápida, indicador, feedback, movimiento reducido, objetivos táctiles y 320/360/390 dp con texto al 200 %. Las pruebas móviles seleccionan Diseño 1 antes de ampliar el texto; no constituyen una auditoría del menú experimental con fuentes grandes.

Se actualizan las expectativas antiguas que buscaban la quinta pestaña DEV. En las pruebas de ruta se consulta `GoRouterState.of(context)` para verificar `/profile`: el proveedor de URL puede conservar la ubicación de origen al usar navegación imperativa, sin que eso signifique que se mostró otra pantalla.

Resultados: 57 pruebas dirigidas distintas aprobadas entre las ejecuciones y repeticiones de los casos corregidos (10 de navegación B, 22 de presentación de barra, 19 de Inicio Diseño 1 y 6 de rutas Login/Splash). Se corrigieron la consulta de URI de las pruebas y el ajuste DEV de título/fecha de Alertas; se repitieron los casos afectados. Análisis estático de los 16 archivos Dart afectados sin incidencias y `git diff --check` satisfactorio. No se abre Edge ni se utiliza hardware físico. No se repite la batería completa de pruebas de la aplicación.

Comandos: `flutter test --no-pub -r expanded test/four_destination_navigation_test.dart test/navigation_visual_preview_test.dart test/route_studio_home_test.dart test/premium_login_route_test.dart`; repeticiones filtradas con `--name 'Four DEV destinations'` y `--plain-name 'Profile header supports keyboard and system back returns to origin'`. Validación física pendiente del usuario.

## Revisión en Android

Archivos del incremento:

- Navegación: `lib/navigation/app_router.dart`, `main_shell.dart` y `navigation_visual_preview.dart`.
- Componente nuevo: `lib/widgets/profile_header_action.dart`.
- Inicio: `lib/screens/home/home_screen.dart`, `premium_home_content.dart`, `guardian_header.dart`, `signature_home_directions.dart` y `route_studio_home.dart` (este último solo reutiliza el botón de su cabecera).
- Otras cabeceras: `lib/screens/alerts/alerts_screen.dart`, `lib/screens/vehicle/vehicle_screen_placeholder.dart` y `lib/screens/history/history_screen_placeholder.dart`.
- Pruebas: `test/four_destination_navigation_test.dart` (nuevo), `test/navigation_visual_preview_test.dart`, `test/route_studio_home_test.dart` y `test/premium_login_route_test.dart`.
- Documentación: este informe. El informe previo de `alerts_review` y `chevi.webp` permanecen intactos y fuera del incremento.

Detener la ejecución anterior y arrancar de nuevo `flutter run -t lib/main_dev.dart` (o el modo profile habitual). La estructura de rutas se crea al iniciar `UrbesApp`: no basta con Hot Reload para cambiar de cinco ramas a cuatro. También sirve Hot Restart en debug.

Tras el Login mock, seleccionar **Diseño 1 · Ruta y Estudio (DEV)** en el selector existente. La barra DEV ya tiene cuatro destinos automáticamente, también en las variantes anteriores. Abrir Perfil desde cada cabecera y volver mediante Atrás; comprobar pestaña/scroll, cierre de sesión y prioridad crítica desde los controles mock existentes. La elección inicial de variante de Inicio no cambia y MAIN continúa con Guardian Deck.

Solo es necesaria la app DEV encendida. SDA, bridge y Firebase real pueden permanecer apagados/desconectados. Internet no es necesario para repositorios mock; las fuentes mantienen su configuración existente. El agente no usa el teléfono físico: la validación final corresponde al usuario. Se detiene aquí, sin consolidar en MAIN.

## Ajuste posterior aprobado — acceso persistente a Perfil

Tras conservar el Incremento B, el usuario autorizó fijar únicamente la fila compacta de cabecera. Se añade `lib/widgets/pinned_profile_header.dart`, basado en `SliverPersistentHeader(pinned: true)`, y se reutiliza `ProfileHeaderAction`. Inicio DEV muestra el lockup vectorial oficial a la izquierda y Perfil a la derecha. Saludo, subtítulo, cartografía decorativa, hero y datos siguen dentro del scroll; no se fija la cabecera completa ni se duplica la marca. La implementación vectorial existente se expone como `UrbesBrandLockup` sin alterar trazados o colores.

La fila de marca tiene 64 dp de altura, con objetivo táctil de 48 dp y ancho de contenido alineado con Inicio. La variante con título permite crecer según `TextScaler` para hasta dos líneas legibles. La superficie opaca evita que los datos desplazados interfieran con el acceso a Perfil. Alertas DEV fija título y Perfil y conserva la fecha en el contenido, retirando el título duplicado de la lista. Vehículo e Historial mantienen sus AppBar existentes, ya persistentes; no se rediseñan.

El ajuste se aplica también a las referencias anteriores de Inicio en DEV. MAIN continúa con cinco destinos y su cabecera previa; no cambia el router respecto al checkpoint B, los datos, la autenticación, Login o D. Los cambios funcionales de contactos desarrollados fuera de esta tarea permanecen intactos.

Pruebas específicas en `test/pinned_profile_header_test.dart`: scroll de Inicio y Alertas, acceso visible y pulsable a Perfil, regreso conservando pestaña y desplazamiento, una única cabecera, objetivos táctiles y adaptación a 320/360/390 dp con texto 100/200 % y movimiento reducido; MAIN sin cabecera nueva. Resultado: 64 pruebas dirigidas distintas aprobadas entre las ejecuciones (las 57 regresiones de B y 7 casos de persistencia). Se repitieron los 7 casos nuevos después de corregir una comparación demasiado estricta de precisión decimal en el test de área táctil: 48 dp se representaba como 47,99999999999999 al restar bordes. No fue necesario cambiar el tamaño del botón. Análisis estático de 9 archivos sin incidencias. No se abrió Edge ni se usó hardware físico.

Para revisar: Hot Restart en debug o detener y ejecutar de nuevo DEV en profile. Elegir Diseño 1, desplazar Inicio y Alertas y abrir Perfil sin volver arriba. No se crea un nuevo panel, no se modifica la ilustración y no se requiere SDA, bridge o Firebase real encendidos.
