# Silent Guardian — navegación inferior DEV

**Decisión vigente: [Pill Active predeterminada compartida](ADOPTION.md), aprobada por el usuario en Edge.** Actual y Underline permanecen como alternativas DEV. La siguiente comparación documenta la exploración anterior; los valores predeterminados y límites vigentes se detallan en la adopción. Esta aprobación visual no autoriza despliegue.

## Registro de exploración previo (histórico)

Dos alternativas para revisión humana en esa etapa, conservando entonces la barra Material de producción y la lógica existente de cinco destinos. Sin cambios en router, autenticación, Firebase, datos o pantallas funcionales. La adopción compartida posterior se documenta en el enlace inicial.

## Composición y comparación

| Elemento | A · Underline | B · Pill Active |
|---|---|---|
| Contenedor | Blanco flotante, esquinas 28 dp, borde tenue y sombra de contacto | El mismo contenedor, para comparar el estado activo sin cambiar el layout |
| Estado activo | Subrayado Teal de 28×3 dp que se desliza entre destinos | Fondo suave `#CCF7F3` de ancho constante por destino, esquinas 18 dp |
| Iconos/labels | Icono Navy, leve elevación visual y label con mayor peso | Mismo lenguaje, integrado en el fondo pill |
| Toque/foco | Feedback Material, énfasis discreto al presionar, foco Teal visible | Las mismas microinteracciones y objetivos táctiles |

La barra se separa 12 dp del borde inferior y laterales, además del espacio seguro del sistema; margen superior 8 dp. Ancho máximo 600 dp en ventanas grandes. Se reserva espacio en Scaffold: el efecto flotante no cubre contenido o acciones. Los cinco destinos y sus iconos/labels proceden del inventario actual de `MainShell`: Inicio, Alertas, Vehículo, Historial y Perfil. Emergencia sigue siendo un flujo aparte, sin barra.

Paleta local de revisión: Navy `#031B3B`, Teal `#006D68`, selección suave `#CCF7F3`, blanco y neutros existentes. Sin gradientes, blur de fondo, iconos externos ni nuevos estados de negocio. Material Icons permanece como familia disponible de comparación; no se cierra la biblioteca definitiva.

## Cómo comparar con Hot Reload

Ejecutar `lib/main_dev.dart` y entrar con datos ficticios al mock. DEV abre **A · Underline** de forma predeterminada. Sobre el botón existente de herramientas aparece un control de ajustes cuyo tooltip es **Comparar navegación: A · Underline**. Ofrece:

- **Actual:** NavigationBar anterior para referencia.
- **A · Underline**.
- **B · Pill Active**.

Cambiar de variante conserva destino, ramas y scroll. El selector existe solo en el shell normal DEV: no se añade a Login, pantallas secundarias fuera del shell o Emergencia. El botón anterior **Panel de desarrollo** mantiene su operación. No hay nueva ruta o página de revisión.

La selección es local a la sesión DEV y permanece al cerrar/reabrir sesión mock dentro de la misma ejecución. Un reinicio comienza en Underline. Si Hot Reload no incorpora el wrapper nuevo de entrada en una sesión existente, reiniciar DEV una vez y luego continuar las iteraciones con Hot Reload. No se altera la colocación externa de `DevBrandIntroHost` ni su estado por la selección de navegación.

## Responsabilidades e integridad funcional

`MainShell` conserva exactamente `shell.goBranch(index, initialLocation: index == shell.currentIndex)`. El router sigue usando `StatefulShellRoute.indexedStack`. No se intercepta el toque ni se espera a terminar una animación para seleccionar una rama.

`NavigationVisualPreview` transporta únicamente variante/acción de revisión. `DevNavigationReview` posee esa selección y se instala dentro del host aprobado de `main_dev.dart`. `MainShell` exige tanto modo DEV como ese scope para usar las alternativas. Sin ellos, incluso si se proporciona accidentalmente el scope a una app sin modo DEV, se conserva la NavigationBar original y no se instala movimiento de contenido.

Un único `NavigationPreviewContentMotion` contiene el mismo shell retenido en las tres opciones DEV. No usa AnimatedSwitcher, no clona Navigators y no cambia sus keys. Los hijos de cada rama, sus entradas previas y posiciones de scroll permanecen vivos. El cambio Actual/A/B tampoco reconstruye otro árbol de navegación.

## Tiempos y respuesta

| Movimiento | Parámetros |
|---|---|
| Indicador conectado | 180 ms, `Curves.easeOutCubic`; retargeting desde la posición visible al seleccionar rápido. |
| Icono activo | Hasta −2 dp y escala 1,04, misma curva/180 ms. |
| Presión | Escala del icono 0,94→1, 90 ms; feedback/splash Material al toque. No vibración personalizada nueva. |
| Labels | Cambio de peso/color en 180 ms; todos permanecen visibles, sin expansión de slots. |
| Contenido seleccionado | Entrada horizontal de 6→0 dp y opacidad 0,94→1 en 180 ms; dirección según el salto de índice y sentido de lectura. No fade de salida o copia de la página previa. |
| Toque en destino ya activo | Conserva el contrato anterior de `goBranch`; no reinicia una entrada decorativa. |

La transición de contenido ocurre sobre el destino ya seleccionado y mantiene semántica e interacción disponibles. No hay espera funcional. Un incidente crítico sigue redirigiendo fuera del shell por las reglas existentes y retira barra/controles de revisión.

Movimiento reducido elimina desplazamientos/escalas decorativos y muestra el indicador en su destino, incluso al activar la preferencia durante un movimiento. La cancelación de animaciones se limita al indicador/iconos: no destruye el foco de los botones o el shell. No hay animaciones de atención infinitas.

## Accesibilidad y rendimiento

- Hit areas ≥48×48 dp en 320/360/390 dp; controles de comparación de 48 dp.
- Labels persistentes a 100/200 %, sin ellipsis ni reducir la fuente para encajar; la altura crece con el texto. Se mide el tamaño de cinco etiquetas en layout/cambios de configuración, fuera de los ticks de animación.
- Navegación por Tab/Enter, foco visible, semántica de botón seleccionado y grupo excluyente; iconos/labels visuales no se anuncian dos veces.
- SafeArea inferior y espacio reservado; sin superposición con contenido. No se introduce haptic propio ni dependencias.
- Widgets de movimiento pequeños, hijos retenidos, recursos/iconos actuales y sin filtros de fondo. Pruebas VM no acreditan FPS, batería o rasterización Android.

Revisión humana pendiente: contraste percibido y ritmo en Edge, ergonomía/tamaño real Android, TalkBack y decisión Underline/Pill antes de promover a componente definitivo. El tratamiento de fuentes y estados globales sigue usando la infraestructura existente; no se aprueba el Design System global.

## Archivos y validación

- `lib/navigation/navigation_visual_preview.dart`: scope opcional y piezas visuales de revisión; sin router o repositorios.
- `lib/screens/dev/dev_navigation_review.dart`: selector y estado exclusivamente DEV.
- `lib/navigation/main_shell.dart`: integración de presentación, conservando inventario/callbacks.
- `lib/main_dev.dart`: instalación de la comparación dentro del host existente.
- `test/navigation_visual_preview_test.dart`: pruebas dirigidas de interacción, accesibilidad e integración.
- Este documento.

```powershell
flutter test --no-pub -r expanded test/navigation_visual_preview_test.dart
flutter analyze --no-pub lib/main_dev.dart lib/navigation/main_shell.dart lib/navigation/navigation_visual_preview.dart lib/screens/dev/dev_navigation_review.dart test/navigation_visual_preview_test.dart
```

**Validación final: 34 pruebas distintas satisfactorias** (21 nuevas de navegación y 13 regresiones de `motion_pilot_test.dart` / `emergency_flow_test.dart`). La primera ejecución detectó dos aserciones excesivamente precisas para la aproximación numérica de la curva Bézier Flutter; se ajustó la tolerancia del desplazamiento intermedio a 0,01 dp, sin modificar el movimiento por ese motivo. Las 20 pruebas de variantes volvieron a pasar; una prueba posterior adicional verificó el entrypoint DEV real, Login/D, logout sin replay y selección conservada al volver a autenticar. No se repite toda la batería del proyecto.

**Análisis estático de cinco objetivos: cero incidencias.** `git diff --check` satisfactorio. El inventario de destinos coincide con HEAD y la llamada `goBranch` conserva su contrato. Router, `main.dart`, autenticación, estado/repositorios, tema global, código Login/D, Android/web y dependencias no presentan cambios de contenido. Las únicas modificaciones son las seis rutas de este incremento. No se abre Edge ni se utiliza hardware.

Para la revisión: app Flutter DEV en Edge con mocks; SDA apagado, bridge detenido, celular innecesario y Firebase real sin uso. Internet solo si lo requiere el mecanismo de fuentes existente. Sin commits ni push; detenerse para elegir la dirección visual.
