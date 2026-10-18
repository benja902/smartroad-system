# Guardian Deck — cabecera, conectividad y actividad

**Decisión posterior aprobada:** Guardian Deck + Editorial Minimal + ilustración lineal se adoptan como predeterminados compartidos en MAIN y DEV. Véase [ADOPTION.md](ADOPTION.md). La exploración de cabecera B y las limitaciones de renders descritas debajo son históricas.

Estado: propuesta DEV para revisión física. MAIN conserva Inicio actual. No crea otra HomeScreen ni aprueba acabado o Design System global.

## Cabeceras seleccionables

En el menú DEV existente: **C · Guardian Deck → Cabecera de Guardian → A · Editorial Minimal / B · Signature Header**. Son selecciones independientes de las ilustraciones A/B del vehículo. B es la elección inicial de exploración, de acuerdo con la preferencia del usuario; no es una promoción a MAIN.

| A · Editorial Minimal | B · Signature Header |
| --- | --- |
| Marca oficial y una jerarquía de saludo/descripcion más precisa, sobre el fondo neutro. | La misma marca, contenido y alineación, con superficie fría degradada hacia el canvas y un motivo vial propio, estático y sutil. |
| [Render Flutter a 320 × 844](guardian_header_editorial.png) | [Render Flutter a 390 × 844](guardian_header_signature.png) |

El motivo no es un mapa, señal de conexión, localizador ni acción. No hay avatar ni botones de relleno. La tipografía es Manrope, saludo de 28 sp, cuerpo de 14 sp y ritmo vertical compartido. La marca se mantiene alineada con contenido y tarjeta. Ambos renders usan la misma ilustración 2.5D simbólica del vehículo; sus diferencias de ancho sirven para revisar adaptación, no para comparar proporciones en condiciones idénticas. El selector permite compararlas en el mismo dispositivo.

`guardian_header.dart` contiene únicamente esta presentación local. El submenú de `DevNavigationReview` y `HomeVisualPreview` retiene la elección sin sustituir Providers, formulario o ramas. La prueba de selección conserva el tamaño de la tarjeta y la expansión de datos técnicos.

## Conectividad y ubicación

Una sola superficie blanca: tres filas con el mismo sistema de icono en contenedor tonal de 34 dp, etiqueta, valor y detalle, alineadas sobre una guía común. Divisores interiores distinguen grupos sin crear tarjetas por propiedad.

- Red móvil: tecnología recibida y registro reportado; no se deduce conectividad integral.
- GNSS: fix reportado/sin fix/sin datos, conservando la interpretación existente.
- Posición recibida: pin, coordenadas cuando hay fix y texto contextual solo cuando corresponde. Sin mapa o afirmación de actualidad; las ausencias conservan sus mensajes neutrales.
- Datos técnicos opcionales: mismo desplegable de voltaje, señal y microSD, sin cambiar valores ni inferir porcentajes, umbrales o frescura.

El texto crece y envuelve en pantallas estrechas; no se elide un dato funcional. Las filas no son botones. La expansión mantiene sus 180 ms o duración cero con movimiento reducido.

## Actividad reciente

La misma lista clasificada, ordenada y limitada a tres registros. Título más legible, estado explícito como información secundaria de contexto y fecha relativa por debajo. El estado se etiqueta a partir de `classify`, sin introducir reglas: «Visto por ti», «Cancelado desde el SDA», «Recepción diferida», «Requiere atención», «Emergencia activa», «Evento técnico» o «Evento informativo».

Impactos/volcaduras usan iconografía de colisión; reconocimiento personal usa visibilidad, sin sugerir resolución. Las filas son informativas, con semántica agrupada y altura mínima de 76 dp que puede crecer. No se añade ripple, foco de botón o callback ficticio. «Consultar alertas» conserva su acción y feedback Material, con superficie tonal Teal coherente. El banner moderado y el flujo crítico no se alteran.

## Archivos y garantías

- `home_visual_preview.dart`, `dev_navigation_review.dart`, `home_screen.dart`, `premium_home_content.dart`: selección y paso de presentación, sin nueva lógica de datos.
- Nuevo `guardian_header.dart`: dos tratamientos del mismo encabezado.
- `guardian_deck_refinement.dart`: solo conectividad/ubicación; el módulo `_GuardianDeck` y el pintor `_GuardianIsometricArt` permanecen idénticos a HEAD, comprobados por comparación de código.
- `recent_alerts_preview.dart`: presentación opcional Guardian; defaults, clasificación, límite, orden y acciones anteriores conservados.
- `home_visual_preview_test.dart`, `guardian_visual_review_test.dart`, dos renders propios y este documento.

No se cambia Pill Active, navegación, Providers/repositorios, Firebase, autenticación, Login, Splash D, dependencias ni tema global. Sin staging, commits o push.

## Validación y limitaciones

**36/36 casos satisfactorios:** 34 pruebas funcionales de Inicio y dos renders. Cobertura de selección de cabecera sin pérdida de datos/expansión, tamaño de tarjeta, ausencia de avatar, iconos/etiquetas de actividad sin acciones falsas, datos/error/ausencia, reconocimiento y prioridad crítica, teclado y movimiento reducido. Signature se verifica con ambas ilustraciones a 320/360/390 dp y texto 200 %; Editorial añade comprobación específica a 320 dp y texto 200 %. Análisis estático de nueve archivos Dart: **sin incidencias**.

La primera pasada detectó cuatro etiquetas con tildes dañadas durante la edición y una comprobación de cabecera que necesitaba volver arriba en el scroll; se corrigieron y la pasada final completa es satisfactoria. Se actualizaron los mismos dos renders, sin producir una colección adicional de capturas.

El conector devolvió inventario de navegador vacío. Se inspeccionaron brevemente los dos renders Flutter con fuentes locales: marca, jerarquía, superficie B, adaptación A y parte superior de conectividad. No se ejecutó Edge ni hardware físico. La actividad y sus estados se verificaron mediante pruebas; su acabado visual completo y las interacciones quedan para revisión humana en el celular. Los renders no certifican rendimiento Android, rasterización web o TalkBack.

El test opcional sigue ejecutándose con `flutter test --no-pub -r expanded --dart-define=URBES_EXPORT_GUARDIAN=true test/guardian_visual_review_test.dart`; ahora exporta `guardian_header_signature.png` y `guardian_header_editorial.png`. Los renders antiguos `guardian_390.png`/`guardian_320.png` se conservan como evidencia histórica. El SDK de iconos del test se configura con `URBES_FLUTTER_SDK` según la documentación previa.

Para revisar: Hot Reload y el submenú indicado; Hot Restart si la sesión anterior no incorpora el campo nuevo. Utilizar únicamente el entorno DEV mock; SDA, bridge, Firebase e Internet no se requieren para los mocks. El celular solo debe estar conectado/encendido si el usuario decide realizar su revisión física. Se espera aprobación antes de consolidar el diseño.
