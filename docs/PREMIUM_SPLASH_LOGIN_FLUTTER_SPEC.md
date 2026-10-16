# URBES Premium Splash & Login — SDD e incrementos Flutter DEV

16 de octubre de 2026. **Variante D aprobada como referencia artística y de movimiento.** Implementación incremental; aprobación visual no equivale a aprobación de rendimiento Android ni del Design System global.

## Consolidación y trazabilidad

Fuentes vigentes: `docs/ui_ux/premium_phase1/motion_prototype_01/` (`mode=beacon`) y `composition_v3/`. Las variantes A–D quedaron guardadas en `bc1b10d`; v3 en `d06096d`; propuesta estática sin T4 en `d6d73c9`. La comprobación previa encontró estas fuentes sin cambios pendientes. Solo permanece ajena al incremento la captura local `05_urbes_login_prototipo.png`, sin versionar. No se necesita otro checkpoint visual antes de comenzar; no se ejecutan commits aquí.

D mantiene perspectiva isométrica 2.5D, cinco árboles (T4 ausente), vehículo e isotipo oficial. El recorrido web usa un perfil quíntico por distancia proyectada de 600 a 2600 ms; isotipo entra 720–960 ms; una elevación/regreso de 2 unidades entre 960–2160 ms; reacción por proximidad a 2400 ms de hasta 3 unidades durante 280 ms; salida 2680–3360, reposo hasta 3540, entrega hasta 4090 y entrada escalonada del formulario hasta 4410 ms. Total de referencia 4440 ms. Ninguno de esos tiempos se impone al arranque Flutter en el Incremento 1.

## Alcance autorizado del Incremento 1

Una **escena estática nativa** visible manualmente desde el panel DEV existente. Se congela D en **2160 ms**, con el entorno construido, el auto cerca del destino y la baliza estable antes de la reacción. No es el primer fotograma del futuro Splash ni una reproducción de toda la secuencia. No cambia el arranque actual, `main.dart`, Login, Provider, GoRouter, Firebase, repositorios, tema global o recursos nativos Android.

No se usa WebView, runtime SVG, Rive, Lottie, dependencia nueva ni una conversión automática de la aplicación. No se instala ni ejecuta en hardware físico.

## Correspondencia web → Flutter

| Fuente | Preparación nativa | Responsabilidad |
|---|---|---|
| D real, instantánea v3 de 2160 ms | Trazados `Path` generados y pinturas por objeto | Fuente visual reproducible; no editar el Dart generado a mano. |
| Grupos suelo, carretera, casa, pabellón, árboles, banco y farolas | Capas conservadas en su orden de pintura | Ilustración estática, sin cronología ni acceso a datos. |
| Vehículo proyectado por `vehicle.js` | Geometría visible congelada de esa pose | No se implementa todavía su renderer móvil ni se alternan poses. |
| `logo.svg` oficial | Tres trazados exactos, transformaciones y colores preservados | El SVG original permanece intacto; no se recrea visualmente a ojo. |
| Sombra estable de D | Elipse de la escena en ese instante | Estática; no flotación, onda o impulso. |
| Layout web 390×844 | Escena normalizada a 620×430, ajustada uniformemente al espacio disponible | Adaptación Flutter responsive; no copiar dimensiones de formulario. |

El generador de biblioteca estándar `docs/ui_ux/premium_phase1/flutter_increment_1/generate_geometry.py` comprueba los hashes de Motion contra v3, lee únicamente el SVG de la instantánea aprobada y prepara los comandos Dart. Falla ante primitivas o transformaciones no soportadas; no es un parser SVG de producción. Conserva trazados cúbicos/cuadráticos/arcos, opacidades y transformaciones de trazo; las marcas discontinuas se preparan antes de proyectar la carretera. Solo prepara este recurso, no pantallas, autenticación o navegación.

## Componentes e integración DEV

- `PremiumScenePainter`: pintura nativa de los recursos; se ajusta con escala uniforme. Paths, pinturas y marcas viales se preparan una vez. No hay lectura de archivos, XML ni interpolación durante `paint`.
- `PremiumScenePreview`: encuadre de revisión nativo con instrucciones de cierre. No es otra app, ruta ni Login.
- `DevBrandIntroController` / `DevBrandIntroHost`: se reutilizan para abrir/cerrar la inspección. La vista estática no inicia ticker ni espera 4,44 s; permanece hasta omisión o interrupción. La intro anterior sigue en su botón y conserva su arranque automático previo.
- `DevSimulatorScreen`: una acción adicional, junto a «Reproducir intro URBES».

El dibujo es presentación sin estado funcional. El host conserva la responsabilidad de ciclo de vida y prioridad; el router sigue decidiendo el destino. Los próximos incrementos introducirán movimiento por separado, sin convertir estos recursos en una nueva arquitectura global.

## Garantías y criterios de aceptación

| Criterio | Comprobación |
|---|---|
| Fidelidad de perspectiva, posición, color y cinco árboles | Comparación del render nativo a 620×430 con la instantánea D normalizada; registrar cualquier diferencia. |
| No animación encubierta | Imagen idéntica después de diez segundos; la inspección no tiene duración automática. |
| Intro anterior disponible | Reproducible después de cerrar la inspección. |
| Omisión | Toque y una única acción semántica cierran sin cambiar la ruta. |
| Emergencia | Evento mock crítico cierra inmediatamente y deja actuar al router vigente. |
| Segundo plano | Se cierra y no vuelve a abrir al reanudar. |
| Movimiento reducido | Se conserva la política del host: omitir decoración, incluida inspección manual, y cerrarla si cambia la preferencia. |
| Contenido cubierto | Sin foco, interacción de puntero ni semántica del contenido bajo el overlay. |
| Pantalla pequeña/texto 200 % | Escena encajada sin deformación ni overflow en 320×640. |
| Separación de producción | Sin modificaciones a entrada de producción, Login, tema, rutas, Firebase o contratos. |

La política de omisión de la inspección manual con movimiento reducido es una decisión conservadora heredada del host, no una limitación del painter estático. No se interpreta como certificación completa de TalkBack.

## Validación y revisión humana

Las pruebas locales usan mocks y recursos vectoriales; no Firebase real ni hardware. Se ejecutan en primer plano con `-r expanded`, deteniéndose si no hay salida durante 60 s. El análisis estático es dirigido. La revisión física de fluidez, memoria y arranque queda expresamente para una etapa posterior autorizada; `shouldRepaint=false` no acredita rendimiento del renderer móvil futuro.

Resultados locales del Incremento 1:

- **36/36 pruebas dirigidas pasan**: siete nuevas en `premium_scene_test.dart`, más regresiones de intro, simulador, emergencia, motion pilot y app DEV.
- **Análisis estático: cero incidencias** en los componentes DEV modificados/creados y la nueva prueba.
- **APK Android profile DEV compilado correctamente**, objetivo `lib/main_dev.dart`: `build/app/outputs/flutter-apk/app-profile.apk` (77 536 737 bytes). No instalado ni ejecutado en hardware. El primer intento con el wrapper Flutter se detuvo tras 60 s sin progreso; el segundo, Gradle en modo offline con salida por tareas, completó `assembleProfile` en 6 min 1 s. Se conservaron las dependencias y configuraciones existentes. Hubo advertencias de plugins Kotlin/Firebase y deprecaciones Gradle; no se actualizaron dependencias ni se considera esto perfilado de rendimiento.
- Comprobación de procedencia: `composition_v3/generate.mjs --check` confirma que v3 corresponde a las fuentes Motion vigentes.
- Comparación visual nativa/SVG a 620×430: error absoluto medio por canal **0,0627 sobre 255**; **0,0495 %** de píxeles con diferencia máxima por canal superior a 16. Se inspeccionaron ambas capturas; perspectiva, cinco árboles, vehículo e isotipo coinciden. Es evidencia de fidelidad a esa resolución, no un umbral de aprobación universal ni una prueba en Android.
- La prueba de texto al 200 % detectó un problema de estilo heredado fuera de la ruta; se corrigió haciendo que el encuadre DEV use `Material`. La prueba de omisión semántica comprueba una única acción accesible.

Comandos de validación:

```powershell
flutter test --no-pub --dart-define=URBES_EXPORT_SCENE=true -r expanded test/premium_scene_test.dart test/brand_intro_test.dart test/dev_simulator_test.dart test/emergency_flow_test.dart test/motion_pilot_test.dart test/widget_test.dart
flutter analyze --no-pub lib/screens/dev/premium_scene lib/screens/dev/brand_intro/dev_brand_intro.dart lib/screens/dev/dev_simulator_screen.dart test/premium_scene_test.dart
node docs/ui_ux/premium_phase1/composition_v3/generate.mjs --check
```

Compilación completada desde `android/` usando los recursos locales existentes:

```powershell
.\gradlew.bat --console=plain --info --offline assembleProfile '-Ptarget=lib/main_dev.dart' '-Ptarget-platform=android-arm,android-arm64,android-x64' '-Pdart-obfuscation=false' '-Ptree-shake-icons=true' '-Ptrack-widget-creation=true'
```

Capturas, generador, manifiesto y procedimiento reproducible: [flutter_increment_1/README.md](ui_ux/premium_phase1/flutter_increment_1/README.md). **El usuario aprobó el Incremento 1 tras ejecutarlo en Android físico y confirmar fidelidad satisfactoria.** Esa validación fue realizada por el usuario; el agente no utilizó hardware.

Para visualizar: ejecutar `lib/main_dev.dart`, abrir el panel DEV y pulsar **Ver escena premium D (estática)**. La intro anterior se conserva en **Reproducir intro URBES**. Cerrar tocando cualquier punto; no se añade navegación. Movimiento reducido debe estar desactivado para inspeccionar esta decoración con la política actual.

No se instala en un celular automáticamente. La configuración actual comparte el identificador Android entre DEV y producción; antes de instalar en un equipo con datos reales hay que autorizar y resolver ese riesgo. No desinstalar la app real como parte de esta tarea. Para esta revisión local: SDA apagado, bridge detenido; Firebase y Emulator apagados/no usados; no se requiere app real ni Internet para los datos mock.

## Incremento 2 autorizado — movimiento aislado del vehículo

La autorización vigente limita este incremento al automóvil. La aparición progresiva de capas se separa para el Incremento 3; no se implementa aquí. El escenario, isotipo y sombra de la baliza permanecen exactamente en la composición del Incremento 1. No hay transición a Login ni interacción con la marca.

### Contrato de movimiento y recursos

- `PremiumVehicleMotion`: traslado de `vehicle.js`, sin rediseñar la ruta. Recta (64,205)→(135,205), Bézier cúbica con controles (198,205), (235,171) hasta (235,113), recta hasta (235,70). Tabla de 841 puntos con distancia acumulada en la proyección del suelo; interpolación continua por búsqueda binaria. Orientación derivada de la tangente en coordenadas del mundo, de 0 a −90 grados.
- Proyección ortográfica fija: `X=300+sqrt(3)/2*(x-y)`, `Y=48+0.5*(x+y)-z`. Las 42 piezas originales giran en el plano del mundo y luego se proyectan. No rotación plana del SVG, atlas de poses ni deformación entre ilustraciones.
- Caras visibles: normal rotada, producto `nx+ny+nz > 1e-7`; profundidad media `x+y+z`, con índice original como desempate. Se estabilizan empates de profundidad a 9 decimales: Dart y JS pueden diferir alrededor de 1e-13 en caras coplanares, sin diferencia geométrica visible. Sombra de 48 vértices y colores/trazos originales. No giro de ruedas añadido.
- Tiempo de revisión: pausa inicial 0–600 ms, recorrido 600–2600 ms (2000 ms), curva quíntica `t³(10−15t+6t²)` aplicada a distancia proyectada. Equivale al reloj D antes de entrega: `t_web=200+tiempo_D`, por lo que la fase web 800–2800 corresponde a 600–2600 en D.
- Al terminar, el auto queda en su destino y el ticker se detiene; la inspección permanece hasta tocar para cerrar. Repetir desde el mismo botón DEV. No espera obligatoria en arranques ni cambio del autoplay de la intro anterior.
- Solo difiere deliberadamente del montaje completo D: entorno e isotipo visibles/quietos desde el inicio; automóvil opaco desde el inicio, sin aparición de 180 ms. No flotación, reacción, onda, entrega de marca ni formulario.

### Separación e integración

`premium_vehicle.dart` contiene trayectoria, proyección y pintor específicos del vehículo. `premium_vehicle_geometry.g.dart` conserva las 42 piezas extraídas por `generate_vehicle.mjs`, que comprueba hashes contra v3. El generador usa Node local sin paquetes; no hay dependencia JS en la app. `vehicle_reference.json` contiene diez muestras del renderer JS como oráculo independiente para pruebas Dart.

`PremiumScenePainter` conserva el modo completo del Incremento 1 y ofrece dos porciones estáticas alrededor de `layer-vehicle`. Tres `RepaintBoundary` mantienen escenario anterior, automóvil y escenario posterior en el orden original; el fondo posterior es transparente. El ticker/notificador del host DEV existente controla solo el pintor del auto, sin reconstruir Provider, router, formulario ni escena por fotograma. Las primitivas dinámicas son pequeñas (42 piezas); su coste Android real sigue pendiente de medición.

Se añade únicamente **Reproducir recorrido del vehículo D** al panel DEV existente. La intro anterior y **Ver escena premium D (estática)** permanecen disponibles. Movimiento reducido omite/cierra el modo; segundo plano lo cierra sin reabrir; un evento crítico mock lo interrumpe y deja actuar al router vigente. Omisión táctil y semántica única disponibles durante todo el recorrido.

### Criterios y validación

Comparar posición, tangente, caras visibles, orden y vértices proyectados con el JavaScript original en diez instantes; muestrear 1201 posiciones para continuidad y giro monótono. Capturar inicio, curva, instante 2160 y destino, inspeccionando fidelidad y superposición. Ejecutar regresiones dirigidas del host, intro, emergencia y movimiento reducido, más análisis estático y compilación DEV. La revisión humana de fluidez en Android permanece pendiente; las pruebas geométricas no certifican FPS.

Resultados locales: **44/44 pruebas pasan**, ocho nuevas del vehículo más las 36 anteriores. Análisis dirigido: **cero incidencias**. Las diez muestras JS coinciden en posición/ángulo/vértices/profundidad con tolerancia 1e-9, y visibilidad/orden exactos tras estabilizar empates coplanares; 1201 muestras conservan continuidad y orientación monótona. Las cuatro capturas nativas se generaron sin excepciones; se inspeccionaron inicio, curva y destino. A 2160 ms, comparación con la escena estática aprobada: error medio por canal **0,00007252 sobre 255**, cero píxeles con diferencia superior a 16. Las pequeñas diferencias proceden del redondeo de coordenadas SVG frente a la reproyección nativa.

```powershell
node docs/ui_ux/premium_phase1/flutter_increment_1/generate_vehicle.mjs
dart format lib/screens/dev/premium_scene/premium_vehicle_geometry.g.dart
flutter test --no-pub --dart-define=URBES_EXPORT_VEHICLE=true -r expanded test/premium_vehicle_test.dart test/premium_scene_test.dart test/brand_intro_test.dart test/dev_simulator_test.dart test/emergency_flow_test.dart test/motion_pilot_test.dart test/widget_test.dart
flutter analyze --no-pub lib/screens/dev/premium_scene lib/screens/dev/brand_intro/dev_brand_intro.dart lib/screens/dev/dev_simulator_screen.dart test/premium_vehicle_test.dart test/premium_scene_test.dart
```

El Incremento 1 sigue sin commit, junto con este trabajo autorizado; se conservan sus archivos y la captura ajena al incremento. No se crean commits ni se hace push.

Compilación del Incremento 2: **`assembleProfile` correcto, 3 min 32 s**, con el mismo comando Gradle offline documentado arriba, objetivo `lib/main_dev.dart`. APK actualizado en `build/app/outputs/flutter-apk/app-profile.apk`; no instalado ni ejecutado por el agente. Permanecen las advertencias existentes de Kotlin/Gradle, sin cambios de dependencias o configuración. **El usuario aprobó el Incremento 2 después de comprobar desplazamiento y giro en Android físico.** Se conserva esa implementación; el agente no utilizó hardware.

## Incremento 3 autorizado — construcción progresiva de capas

Nuevo modo **Reproducir construcción por capas D**, en el mismo panel/host DEV. Se conservan los modos estático, vehículo aislado e intro anterior. La escena reutiliza las 15 capas y la misma geometría; no se regeneran ilustraciones ni se cambia trayectoria, orientación o duración del vehículo.

El reloj único sigue siendo de 2600 ms. Antes de entrega, D usa `t_web=200+ms_D`. Las entradas reproducen `easeOutCubic = 1-(1-p)^3`, opacidad de grupo, traslación vertical `dy*(1-p)` y escala `s0+(1-s0)*p` alrededor del pivote original. Los desplazamientos se expresan en coordenadas de diseño 620×430, antes del ajuste uniforme al dispositivo.

| Capa/objeto | Intervalo ms D | Movimiento inicial → final |
|---|---:|---|
| Suelo | −20–320 | Opacidad 0→1; escala 0,985→1; pivote (300,220). A 0 ms ya tiene opacidad ~0,1663, como HTML. |
| Carretera | 70–450 | Opacidad 0→1; escala 0,992→1; pivote (300,220). |
| Casa | 230–630 | Opacidad 0→1; desplazamiento 8→0; escala 0,985→1; pivote (300,120). |
| Parque/grupo paisaje | 300–580 | Opacidad de grupo 0→1, incluida en sus árboles posteriores y farolas. |
| Pabellón | 350–710 | Opacidad 0→1; desplazamiento 6→0; escala 0,985→1; pivote (400,250). |
| Árbol T6 (`tree-5`) | 380–680 | Opacidad 0→1; desplazamiento 4→0; escala 0,98→1. |
| T4 (`tree-3`) | 435–735, oculto | No se dibuja; se conserva su intervalo en el escalonamiento. |
| Árbol T5 (`tree-4`) | 490–790 | Igual entrada de árbol; además opacidad heredada del parque. |
| Árbol T1 (`tree-0`) | 545–845 | Igual entrada de árbol, en primer plano. |
| Banco | 580–840 | Opacidad 0→1; desplazamiento 3→0. |
| Árbol T2 (`tree-1`) | 600–900 | Igual entrada de árbol, en primer plano. |
| Farolas | 640–900 | Opacidad 0→1; desplazamiento 3→0; además opacidad heredada del parque. |
| Árbol T3 (`tree-2`) | 655–955 | Igual entrada de árbol, en primer plano. |
| Vehículo | 600–780 entrada; 600–2600 recorrido | Opacidad **lineal** 0→1 del grupo completo, incluida su sombra. Recorrido/quintic del Incremento 2 sin cambios. |
| Isotipo y sombra de baliza | Estáticos | Conservan el estado estable del Incremento 1; sin entrada, flotación, reacción ni salida. |

El contenedor de arquitectura está ya totalmente visible en el reloj D inicial (su entrada HTML es 0–1 ms del reloj interno); la animación relevante es la de la casa. El parque mantiene la opacidad sobre el grupo compuesto, no solo sobre el césped ni multiplicada por separado en cada trazo. Así se conserva la superposición entre sus objetos semitransparentes.

### Responsabilidades y rendimiento

`premium_scene_motion.dart` define únicamente este contrato de movimiento. `PremiumScenePainter` reutiliza los trazados y registra un `Picture` por capa una sola vez, conservando el orden de pintura; durante la construcción reproduce esas imágenes vectoriales con sus transformaciones/opacidades. `saveLayer` conserva las opacidades de grupo, sin filtros, desenfoques o efectos adicionales. Los objetos totalmente opacos evitan su buffer individual; el grupo padre del paisaje conserva su composición conjunta hasta finalizar la construcción. El coste temporal de estos buffers queda pendiente de perfilado Android.

El host deriva `_sceneProgress` del reloj existente y lo limita a 955/2600: no hay otro ticker y el escenario deja de invalidarse después de 955 ms. El notificador del automóvil continúa hasta 2600 ms. No se reconstruyen Provider/router/formulario por fotograma. `PremiumVehiclePainter(reveal:true)` añade solo la entrada de opacidad; el modo aislado mantiene el comportamiento aprobado del Incremento 2.

### Validación y diferencias conocidas

`generate_scene_reference.mjs` comprueba el hash de `prototype.js` y evalúa sus llamadas originales a `reveal` para producir `scene_reference.json` (12 instantes). No es otro prototipo HTML ni una nueva dependencia. Las pruebas contrastan opacidades y transformaciones, incluida la opacidad padre del paisaje, y comprueban el reloj compartido, fin de invalidación, omisión, emergencia, segundo plano y movimiento reducido. Las regresiones anteriores se conservan. La prueba del panel espera ahora el layout después de desplazar los controles, porque el botón nuevo cambia su posición visible.

Diferencias deliberadas frente a D completa: isotipo/sombra estables y visibles desde el inicio; sin texto URBES, flotación, onda, reacción, salida ni Login. El prototipo termina en el destino a 2600 ms y permanece inspeccionable hasta omitir. La apariencia final mantiene la escena aprobada. Capturas de validación `layers_0/380/720/955/2160.png` en la carpeta de preparación existente. Las métricas y capturas no acreditan rendimiento Android; la revisión humana del Incremento 3 sigue pendiente.

Resultados locales: **50/50 pruebas dirigidas pasan**, seis nuevas de capas y las 44 anteriores. Las 12 muestras de las llamadas originales a `reveal` coinciden con tolerancia 1e-12 en opacidad, escala y desplazamiento; se conservan pivotes y hueco temporal de T4. Capturas parciales a 380 y 720 ms inspeccionadas. En 2160 ms frente al render aprobado del Incremento 2: error absoluto medio por canal **0,00411 sobre 255**, cero píxeles con diferencia superior a 16; diferencias leves de rasterización/composición vectorial documentadas en `scene_visual_comparison.json`.

Análisis estático dirigido final: **cero incidencias** en los componentes DEV y pruebas modificadas. `composition_v3/generate.mjs --check` confirma que las fuentes HTML siguen correspondiendo a v3, sin modificaciones. No se instalaron dependencias ni se usó hardware, Firebase real, SDA o bridge.

Compilación Android del Incremento 3: **`assembleProfile` correcto en 3 min 13 s**, offline y con progreso por tareas, objetivo `lib/main_dev.dart`. APK actualizado: `build/app/outputs/flutter-apk/app-profile.apk`. Se conservaron las configuraciones y dependencias existentes; permanecen sus advertencias Kotlin/Gradle. No se instaló el APK ni se midieron FPS/memoria en dispositivo. **El usuario aprobó el Incremento 3 tras revisarlo satisfactoriamente en Android físico y pidió conservar su implementación actual.** El agente no utilizó hardware.

```powershell
node docs/ui_ux/premium_phase1/flutter_increment_1/generate_scene_reference.mjs
flutter test --no-pub --dart-define=URBES_EXPORT_LAYERS=true -r expanded test/premium_scene_motion_test.dart test/premium_vehicle_test.dart test/premium_scene_test.dart test/brand_intro_test.dart test/dev_simulator_test.dart test/emergency_flow_test.dart test/motion_pilot_test.dart test/widget_test.dart
```

## Incremento 4 autorizado — baliza flotante D, sin salida

Se conserva íntegramente la entrada de capas y el recorrido aprobados. No se cambian `premium_scene_motion.dart`, `premium_vehicle.dart`, las geometrías generadas ni los SVG/JS del prototipo. Se añade **Reproducir baliza flotante D** al panel DEV existente, conservando los cuatro modos anteriores para comparación. No hay nuevo entorno de controles.

### Contrato temporal exacto del HTML

| Fase | Tiempo D | Comportamiento |
|---|---:|---|
| Espera | 0–720 ms | Isotipo y sombra ausentes. |
| Entrada | 720–960 ms | Opacidad `1-(1-p)^3` de ambos; sin desplazamiento de entrada añadido. |
| Elevación | 960–1560 ms | Sube 2 px mediante la curva quíntica original. |
| Regreso | 1560–2160 ms | Vuelve suavemente a su ancla con la misma curva. Es un único ciclo, no un bucle. |
| Estabilización | 2160–2400 ms | Reposo durante 240 ms, sin onda. |
| Reacción y onda | 2400–2680 ms | Amplitud `sin²(pi*p)`, impulso máximo de 3 px en la dirección proyectada del auto; pico a 2540 ms. |
| Fin de revisión | 2680 ms | Reposo, onda invisible y ticker detenido. No se inicia el vuelo hacia URBES. |

La reacción conserva también la escala **uniforme** `1+0.035*amplitud` del HTML (máximo 3,5 %). No se deforman ni recolorean los tres trazados originales, ni se gira el isotipo. La sombra permanece en el pie de la baliza: radios `10−0.8*lift`, `4−0.3*lift`, opacidad `(0.11−0.02*lift)*entrada`. La onda es una elipse turquesa rotada −30°, radios `10+12*p`, `4+5*p`, trazo 1,4 px, opacidad máxima 0,65 con la misma amplitud de reacción. No se añaden ondas repetidas, brillo o desenfoque.

**Unidades:** 2 px, 3 px y radios/trazo son píxeles del artboard HTML de 390×844. Su escena se escala a 0,6; Flutter conserva la escena base 620×430, por lo que convierte esos efectos dividiendo por 0,6 antes del ajuste uniforme al dispositivo. No se sustituyen por píxeles físicos de Android. El ancla sigue siendo `project(236,13,26)` y el pie `project(236,13,0)`.

### Sincronización y responsabilidades

`PremiumBeaconMotion` deriva una sola vez el instante de encuentro de la trayectoria existente: muestrea cada milisegundo del recorrido original y busca la primera distancia proyectada entre el frente del auto (44 unidades adelante) y el pie de la baliza ≤16 unidades. El resultado es **2400 ms**; un milisegundo antes todavía está fuera del umbral. La dirección sale de la tangente proyectada real del vehículo en ese instante. No se inventan coordenadas de impacto ni temporizadores independientes.

El reloj del host sigue expresado como tiempo/2600. Solo el modo de baliza permite continuar hasta 2680/2600 para completar la reacción; la posición del auto queda naturalmente limitada a su destino desde 2600 ms, y las capas conservan su notificador detenido desde 955 ms. Los modos anteriores conservan su duración y comportamiento.

`PremiumBeaconPainter`, parte de la biblioteca de escena, reutiliza el `Picture` del isotipo original. Los pintores del escenario omiten únicamente `brand-symbol` y `target-shadow` cuando este modo está activo, y la baliza se pinta una sola vez por encima de la escena, manteniendo sombra→onda→isotipo. No se duplican SVG ni paths del logo. Un `RepaintBoundary` aísla su repintado; el escenario estático no vuelve a invalidarse por la flotación. Omisión táctil/semántica, movimiento reducido, segundo plano y emergencia siguen bajo el host DEV existente.

### Validación local y revisión pendiente

**57/57 pruebas dirigidas pasan**: siete nuevas de baliza más las 50 anteriores. Análisis estático final: **cero incidencias**. `generate_beacon_reference.mjs` verifica los hashes del prototipo y evalúa su función original `drawVariant(false,0)` en 16 instantes hasta 2680 ms; posición, escala, opacidades y radios coinciden con las muestras JS. La prueba de contacto verifica el umbral antes/después del encuentro y muestrea continuidad cada milisegundo. También se comprueban reloj compartido, final sin salida, conservación del modo anterior y las interrupciones obligatorias.

Se generaron seis capturas nativas: `beacon_0/840/1560/2160/2540/2680.png`, en la misma carpeta de preparación. Se inspeccionaron inicio, elevación máxima e impulso máximo. Comparando con las capturas del Incremento 3 a 0 y 2160 ms, **cero píxeles cambiaron fuera del área de baliza** (región de exclusión documentada en `beacon_visual_comparison.json`). A 0 ms, la única diferencia es quitar isotipo/sombra; el suelo inicial aprobado no se retoca. A 2160 ms, el error medio total por canal es 0,00000750 sobre 255; solo leves diferencias de alpha/rasterización de la sombra.

```powershell
node docs/ui_ux/premium_phase1/flutter_increment_1/generate_beacon_reference.mjs
flutter test --no-pub --dart-define=URBES_EXPORT_BEACON=true -r expanded test/premium_beacon_test.dart test/premium_scene_motion_test.dart test/premium_vehicle_test.dart test/premium_scene_test.dart test/brand_intro_test.dart test/dev_simulator_test.dart test/emergency_flow_test.dart test/motion_pilot_test.dart test/widget_test.dart
flutter analyze --no-pub lib/screens/dev/premium_scene lib/screens/dev/brand_intro/dev_brand_intro.dart lib/screens/dev/dev_simulator_screen.dart test/premium_beacon_test.dart
```

Diferencias deliberadas frente a D completa: no texto URBES ni vuelo desde 2680 ms, no desvanecimiento de sombra asociado a ese vuelo, ni transición a Login. Se mantiene la escena inspeccionable al terminar; no se impone una espera al arranque. La revisión humana de este incremento, TalkBack y el perfilado físico permanecen pendientes. El agente no usa hardware, SDA, bridge o servicios reales. No hay dependencias nuevas ni cambios de producción, autenticación, navegación o Firebase; tampoco commits/push.

Compilación Android del Incremento 4: **`assembleProfile` correcto en 3 min 37 s**, offline, con el mismo comando/objetivo `lib/main_dev.dart` de los incrementos anteriores. APK actualizado en `build/app/outputs/flutter-apk/app-profile.apk`; no instalado por el agente. Se mantienen las advertencias existentes Kotlin/Gradle sin actualizar dependencias ni configuración. **El usuario confirmó la aprobación de los cuatro incrementos después de revisarlos satisfactoriamente en Android físico y autorizó un checkpoint Git local previo al Incremento 5.** El agente no utilizó hardware en esta revisión.

## Incremento 5 autorizado — cierre de marca y destino visual Login DEV

El usuario ratificó la aprobación de la baliza en Android y autorizó el cierre de D. Punto de recuperación previo: **`fceba33cb04fb57e11bd2c2ed7cbfb1309bbb014`**, incrementos 1–4. Se preservan las ocho capturas locales ajenas/no incluidas en ese commit. No se hacen nuevos commits ni push.

### Destino de presentación, sin cambios funcionales

Se inspeccionaron `main_dev.dart`, `DevBrandIntroHost`, `SessionProvider`, `AppRouter` y `LoginScreen`. El router depende de la sesión y un mock ya iniciado puede estar en Inicio; instanciar el Login funcional aquí también iniciaría su `ScreenEntrance` y montaría su formulario fuera de la coreografía. Se utiliza **`PremiumClosurePreview` sobre el router vivo**, sin consultar/cambiar la sesión, autenticar, cerrar sesión ni navegar. El destino contiene la cabecera de marca y la ilustración, más una etiqueta de revisión DEV desde 4090 ms. **No hay campos, botones de acceso, formulario, estados ni microinteracciones del Login.**

El modo **Reproducir cierre de marca D** se añade al panel DEV existente. La intro anterior y los modos estático, vehículo, capas y baliza permanecen disponibles. Solo este modo usa el artboard completo 390×844 del HTML, encajado uniformemente dentro de `SafeArea`; los otros encuadres aprobados se conservan.

### Correspondencia exacta con D

| Fase | Tiempo D | Posición/escala/curva |
|---|---:|---|
| Capas, auto y baliza | 0–2680 ms | Contratos de los incrementos anteriores intactos; cambia únicamente el encuadre al artboard de teléfono. |
| Texto URBES bajo la escena | 1900–2200 ms | Entrada de opacidad cúbica de salida, tamaño 32, peso Manrope 800, origen de texto (43,11) relativo al lockup (131,633). No se espera a que llegue el isotipo para mostrar el texto. |
| Vuelo del isotipo | 2680–3360 ms | Bézier cúbica: origen `toPhone(project(236,13,26))`, controles (365,440), (131,510), destino (131,633). Progreso quíntico original; escala del símbolo 0,3→0,6 sobre su caja original 96×96 (28,8→57,6 px). |
| Retirada de sombra | 2680–2800 ms | Alpha previo multiplicado por `1-smoothstep(p)`; la onda ya está extinguida. |
| Marca reunida | 3360–3540 ms | Símbolo y texto quietos bajo la ilustración, como un conjunto. |
| Entrega a cabecera | 3540–4090 ms | `d=smoothstep((ms−3540)/550)`. Lockup: `x=42+89*(1−d)^3`, `y=633−586*smoothstep(d)`, escala `1−0.375*d`. Se conserva deliberadamente el **doble smoothstep vertical** del HTML. |
| Continuidad de la escena | 3540–4090 ms | Su origen pasa (14,270)→(14,71), con `y=270−199*d`; su escala **permanece 0,6**. El HTML desplaza la ilustración, no la reduce en esta fase. |
| Destino estable | 4090–4440 ms | Marca y escena permanecen en cabecera; la etiqueta DEV aparece 4090–4330 ms. Ticker se detiene a 4440 ms y la revisión permanece hasta omitir. |

En destino: origen del conjunto (42,47), escala 0,625; símbolo de 36 px y texto con baseline global (68,875;53,875). No se intercambian representaciones, no hay reapariciones ni fundidos entre duplicados. Se mantienen un solo `Picture` del isotipo oficial y un solo trazado del texto durante todo el recorrido. Los colores del logo y el texto Navy permanecen sin cambios.

### Recursos y separación

- `PremiumClosureMotion`: estado determinista por tiempo; posiciones, Bézier, escalas y curvas extraídas de la referencia. Reutiliza la baliza aprobada antes de la salida, sin modificar su modelo.
- `PremiumSceneArtwork`: composición nativa compartida extraída del encuadre anterior, conservando sus tres límites de repintado y orden de capas. Se reutiliza dentro de una transformación externa; no se reconstruyen geometrías al trasladar la escena.
- `PremiumClosureBrandPainter`: un único isotipo y texto, sombra/onda originales hasta su extinción. El SVG oficial y las geometrías de escena/auto no se editan.
- `premium_wordmark.g.dart`: únicamente los contornos de «URBES» derivados del **Manrope existente, peso 800**, con baseline y tamaño 32 del HTML. `generate_wordmark.py` usa **fontTools ya disponible** en el entorno de autoría; no se instala software ni se añade dependencia Flutter, fuente nueva o asset global en `pubspec.yaml`. OFL/FONTLOG de Manrope siguen en `assets/`; el archivo derivado conserva atribución. No hay carga de fuente ni acceso a red durante la animación. Avance de contornos: 105,408 px; Chrome presenta diferencias de métricas/hinting menores de 0,02 px.

El host mantiene un ticker. El notificador de escena se detiene desde 955 ms y el del vehículo se limita a 2600 ms; el reloj de marca continúa hasta 4440/2600. La traslación externa conserva los hijos cacheados. Los modos anteriores siguen con sus duraciones originales. Emergencia, omisión, movimiento reducido y segundo plano retiran el overlay y dejan actuar a la app subyacente, sin espera de cierre de marca ni destino impuesto.

### Validación y límites

**65/65 pruebas dirigidas pasan**, ocho nuevas del cierre y las 57 anteriores. Tras ajustar exclusivamente la captura de QA, las ocho nuevas volvieron a pasar. **Análisis estático: cero incidencias.** Se verifican quince muestras obtenidas de la función original D, continuidad cada milisegundo y en las uniones 2680/3360/3540/4090; sesión mock intacta; ausencia de formulario/campos; retorno a la misma ruta DEV; emergencia durante entrega; movimiento reducido; segundo plano; pantalla 320×640/texto 200 % y una única acción semántica de omisión.

`export_closure_browser.mjs` captura el **prototipo original** en Chrome headless con perfil temporal aislado, sin crear página o reproductor. Solo se ocultan el formulario fuera de alcance y el marco externo de revisión para comparar el artboard. Los PNG nativos excluyen igualmente la etiqueta DEV de presentación. Se compararon vuelo (3100), marca reunida (3450), entrega (3800) y destino (4440), a 390×844. Error medio por canal entre **0,0633 y 0,0811 sobre 255**, y **0,138–0,174 %** de píxeles con diferencia máxima superior a 16. Se inspeccionaron los cuatro estados. Las diferencias pequeñas corresponden a rasterización, contornos tipográficos y redondeo de captura entre renderers; no son métricas de rendimiento Android.

Diferencias deliberadas frente a la secuencia HTML completa: **no se representa ni anima el formulario**; la etiqueta de revisión sustituye únicamente esa región. No se alteran autenticación, Login compartido, GoRouter, Provider, Firebase, producción ni Design System global. El encuadre se adapta uniformemente al espacio seguro del dispositivo; no se afirma equivalencia con sus píxeles físicos. La revisión humana del cierre, TalkBack y el perfilado Android permanecen pendientes. No se utiliza hardware por el agente.

Compilación Android del Incremento 5: **`assembleProfile` correcto en 3 min 39 s**, offline, objetivo `lib/main_dev.dart`, con el comando Gradle documentado en los incrementos anteriores. APK actualizado: `build/app/outputs/flutter-apk/app-profile.apk`; no se instaló ni ejecutó por el agente. Se mantienen las advertencias Kotlin/Gradle existentes, sin modificar configuración o dependencias. Para revisión: abrir la app DEV y **Reproducir cierre de marca D**; SDA apagado, bridge detenido, sin conexión a Firebase real ni Internet requerido para los datos mock. Al terminar se espera aprobación humana antes del Incremento 6.

```powershell
python docs/ui_ux/premium_phase1/flutter_increment_1/generate_wordmark.py
dart format lib/screens/dev/premium_scene/premium_wordmark.g.dart
node docs/ui_ux/premium_phase1/flutter_increment_1/generate_closure_reference.mjs
node docs/ui_ux/premium_phase1/flutter_increment_1/export_closure_browser.mjs
flutter test --no-pub --dart-define=URBES_EXPORT_CLOSURE=true -r expanded test/premium_closure_test.dart test/premium_beacon_test.dart test/premium_scene_motion_test.dart test/premium_vehicle_test.dart test/premium_scene_test.dart test/brand_intro_test.dart test/dev_simulator_test.dart test/emergency_flow_test.dart test/motion_pilot_test.dart test/widget_test.dart
flutter analyze --no-pub lib/screens/dev/premium_scene lib/screens/dev/brand_intro/dev_brand_intro.dart lib/screens/dev/dev_simulator_screen.dart test/premium_closure_test.dart
```

## Secuencia de seis pasos y límite actual

1. Escena estática DEV: aprobada por el usuario en Android.
2. Movimiento aislado del vehículo: aprobado por el usuario en Android.
3. Construcción progresiva de las capas: aprobada por el usuario en Android.
4. Baliza flotante D y reacción sincronizada: aprobada por el usuario en Android.
5. Reunión de marca y transición a un destino visual DEV: aprobado por el usuario en Android físico; checkpoint local autorizado.
6. Estados/microinteracciones de Login y validación integral de accesibilidad/rendimiento: posterior.

No forzar Login para sesiones activas ni añadir una ruta de Splash que cambie GoRouter. Los incrementos 1–4 están aprobados y conservados en `fceba33`; el usuario confirmó también la validación satisfactoria del Incremento 5 en Android físico y autorizó su checkpoint local. Esta tarea registra ese estado sin modificar código, repetir pruebas Flutter ni hacer push. No se autoriza avanzar al formulario ni al Incremento 6 y se conserva el trabajo local ajeno.

## Incremento 6 autorizado — Login real en la continuidad DEV

El usuario aprobó el Incremento 5 en Android y autorizó esta integración de presentación. Checkpoints verificados: `fceba33` (1–4) y `a5c4d5` (5). Los párrafos anteriores describen sus límites históricos; esta sección amplía exclusivamente el alcance DEV al formulario. No activa el premium en producción. No se hacen commits ni push y se conservan las ocho imágenes locales ajenas.

### Reutilización e aislamiento

`LoginScreen` conserva la propiedad de su único `Form`, controladores, validadores, autofill, contraseña oculta, envío con teclado, `PrimaryButton`, estado ocupado y traducción de errores. Se añade un `LoginPresentationBuilder` opcional que recibe `LoginFormParts`: widgets reales ya conectados a ese estado. El constructor por defecto mantiene la presentación y `ScreenEntrance` anteriores. No se duplica el formulario ni se cambia `_submit`, `_messageFor`, repositorios o contratos de sesión.

`DevPremiumLoginPreview` presenta ese Login sobre el host existente, con un `SessionProvider(MockAuthRepository())` local que no observa el router. Enviar datos ficticios ejercita el envío real contra el mock y muestra una confirmación DEV; no cambia la sesión ni la ruta de la app subyacente. No se cierra sesión global para mostrar Login. Un `Overlay` local proporciona selección/cursor de los campos, sin Navigator ni ruta adicional. Se retira y dispone junto con el formulario. El tema Navy y las superficies se aplican solo a esta revisión; no cambia `AppTheme` global.

Nuevo recorrido del panel existente: **Reproducir Splash → Login real DEV**. Se conservan la intro anterior y todos los modos de los incrementos 1–5. No hay panel HTML nuevo ni recursos vectoriales nuevos.

### Coreografía

Las geometrías y modelos de capas, vehículo, baliza y cierre no cambian. Se reutiliza `PremiumClosureArtboard` sin su etiqueta de destino DEV y sin segunda ilustración/marca. El formulario se monta únicamente al llegar a 4090 ms; no ejecuta una animación privada detrás del Splash.

| Contenido | Entrada D | Movimiento |
|---|---:|---|
| Título y descripción | 4090–4330 ms | Opacidad 0→1, desplazamiento vertical 6→0 px del artboard. |
| Campos y error | 4130–4370 ms | Misma entrada escalonada, controles reales. |
| Botón principal | 4170–4410 ms | Misma entrada escalonada. |
| Destino estable | 4440 ms | Ticker detenido; formulario interactivo, sin espera adicional. |

Las tres entradas usan la función cúbica de salida `1−(1−p)^3` y el reloj único del host. Cabecera e ilustración mantienen el encuadre 390×844 aprobado; el contenido empieza en y=340 con márgenes de 24 unidades. El formulario usa tamaños nativos accesibles y puede crecer verticalmente, a diferencia del dibujo vectorial escalado.

### Teclado, accesibilidad y garantías

Ilustración, marca y formulario comparten un único scroll. El encuadre se calcula con la altura disponible antes de descontar teclado: el viewport se reduce y permite desplazar los campos, sin reducir o saltar la ilustración al abrirlo. Las secciones totalmente transparentes no admiten foco, puntero ni semántica. Los campos y botón mantienen su semántica nativa; el fondo de la app permanece bloqueado durante la revisión.

**Omitir introducción** y movimiento reducido muestran inmediatamente el destino con el formulario, sin reproducir 4,44 segundos. **Cerrar DEV** devuelve la revisión a la misma ruta. Segundo plano retira el overlay y no lo reproduce al volver. Un evento crítico lo retira inmediatamente, libera el foco y deja actuar al flujo de emergencia existente. La revisión no añade esperas obligatorias a ese flujo.

### Validación y diferencias conocidas

Se añaden nueve pruebas de integración: montaje/entradas con reloj D y ausencia de marca duplicada; omisión/validación/autofill/envío mock aislado; carga y errores de cuenta no provisionada/credenciales inválidas; teclado en 320×640 con texto 200 %; movimiento reducido inicial y sobrevenido; emergencia con campo enfocado; segundo plano. La regresión dirigida completa pasa **74/74** (65 anteriores + 9 nuevas).

El formulario se adapta a Material nativo: conserva etiquetas CORREO/CONTRASEÑA, validadores y mensajes existentes, en lugar de sustituirlos por inputs HTML. El Login actual no incluye un botón para revelar contraseña y este incremento no añade esa funcionalidad. El acceso de revisión no navega a Inicio ni llama Firebase: solo confirma el mock local. La ilustración vectorial y la marca conservan la coreografía aprobada; no se afirma equivalencia píxel a píxel del texto/campos entre Chrome y Flutter.

La captura opcional `login_flutter_4440.png` es evidencia propia, no un recurso de ejecución; carga Manrope ya existente únicamente en la prueba de exportación mediante un bundle ficticio de fuentes. También representa el fallback Material con ese Manrope local para evitar los rectángulos de Ahem del runner: sirve para revisar composición, no para certificar métricas tipográficas Android. No hay descarga de fuentes en esa exportación ni cambios del manifiesto de assets de la app. La revisión física de teclado/autofill, TalkBack, contraste en dispositivo y perfilado de cuadros Android queda pendiente del usuario. El agente no instala ni ejecuta en hardware.

**Análisis estático: cero incidencias. Compilación Android DEV `assembleProfile` offline: correcta en 2 min 36 s**, con el comando Gradle de los incrementos anteriores y objetivo `lib/main_dev.dart`. APK en `build/app/outputs/flutter-apk/app-profile.apk`, sin instalar. Se mantienen las advertencias existentes del toolchain Kotlin/Gradle; no se actualizan versiones ni configuración. `git diff --check` pasa; `_submit` y `_messageFor` coinciden con el checkpoint anterior ignorando únicamente formato. Los modelos y geometrías de los incrementos 1–5 permanecen sin cambios. Tras añadir el límite de repintado y completar la captura, las nueve pruebas nuevas se vuelven a verificar sin repetir la compilación ni la regresión completa innecesariamente.

```powershell
flutter test --no-pub -r expanded test/premium_login_test.dart test/premium_closure_test.dart test/premium_beacon_test.dart test/premium_scene_motion_test.dart test/premium_vehicle_test.dart test/premium_scene_test.dart test/brand_intro_test.dart test/dev_simulator_test.dart test/emergency_flow_test.dart test/motion_pilot_test.dart test/widget_test.dart
flutter test --no-pub --dart-define=URBES_EXPORT_LOGIN=true -r expanded test/premium_login_test.dart
flutter analyze --no-pub lib/screens/auth/login_screen.dart lib/screens/dev/premium_scene lib/screens/dev/brand_intro/dev_brand_intro.dart lib/screens/dev/dev_simulator_screen.dart test/premium_login_test.dart
```

Para revisión humana: ejecutar `lib/main_dev.dart`, abrir el panel DEV y seleccionar el nuevo recorrido. Utilizar solo datos ficticios; no requiere Internet ni Firebase real. SDA apagado y bridge detenido. Se detiene el trabajo al terminar este incremento; producción y validación física requieren una nueva decisión.

### Opción de ajuste — escala de la ilustración final

`finalSceneZoom` permite elegir el tamaño de la ilustración final sin editar sus recursos. Para conservar la composición aprobada de D, el modo **Splash → Login real DEV** queda por defecto en `finalSceneZoom: 1.0`, con escala nativa de escena 0,60 durante toda la secuencia. El modo de cierre del Incremento 5 conserva el mismo valor predeterminado.

Como opción de revisión, `finalSceneZoom: 1.1` permite ampliar la ilustración final un 10 %: escala nativa 0,60→0,66 durante 3540–4090 ms, con el mismo `smoothstep` del traslado y creciendo alrededor del centro de la escena. Antes de 3540 ms no cambia la escala; el isotipo ya se reunió con el texto. Marca, formulario, trayectorias y tiempos mantienen sus valores anteriores. Esta opción ofrece mayor elección de encuadre; no está activada por defecto. La captura final corresponde al valor predeterminado `1.0`.
