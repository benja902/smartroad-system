# Guardian Deck — marca, vehículo y lectura de conectividad

**Estado vigente:** combinación Guardian Deck / Editorial Minimal / Lineal aprobada como predeterminada compartida; [ADOPTION.md](ADOPTION.md) documenta la adopción. Las referencias a MAIN con Inicio actual o acabado pendiente en las secciones históricas siguientes corresponden a las revisiones previas.

**Iteración vigente de cabecera/conectividad/actividad:** ver [GUARDIAN_COMPONENT_POLISH.md](GUARDIAN_COMPONENT_POLISH.md). Incorpora Editorial Minimal y Signature Header seleccionables dentro de Guardian, sin modificar el módulo Navy de esta base. Los apartados siguientes conservan la trazabilidad de las iteraciones anteriores.

**Pulido posterior de jerarquía y proporciones:** Guardian conserva la marca oficial alineada a la izquierda, sin avatar. Se reduce el espacio marca–saludo de 26 a 18 dp, los márgenes entre módulos de 24 a 20 dp y el área gráfica de 132 a 120 dp. En la ilustración 2.5D se ajusta el encuadre de 140 a 126 unidades: el vehículo mantiene prácticamente su tamaño aparente, sin alterar su geometría ni perspectiva. La tarjeta alinea disponibilidad y última comunicación en una columna junto al distintivo, retirando la explicación redundante inferior.

Red móvil, GNSS y posición ahora comparten una sola superficie compacta. La disponibilidad del fix se muestra una vez; las coordenadas quedan como lectura secundaria bajo un divisor. Se conserva el criterio anterior de no mostrar coordenadas sin fix, con «Sin coordenadas para mostrar» en esa línea y el estado del fix en GNSS. Los datos técnicos siguen desplegables. No hay cambios de datos, reconocimiento, clasificación ni prioridad de atención/Emergencia. MAIN y las otras composiciones se conservan.

Validación de este pulido: **32/32 pruebas dirigidas de Inicio satisfactorias**, incluidas alineación de marca/saludo/tarjeta, ausencia de avatar, fix no duplicado, ambas ilustraciones a 320/360/390 dp con texto 200 %, teclado, movimiento reducido, estados y prioridad crítica; análisis estático de los cuatro Dart afectados sin incidencias. La primera pasada detectó un error de ubicación del módulo al reagrupar secciones; se corrigió y la pasada completa final es satisfactoria. No se abrió Edge, generaron capturas ni utilizó dispositivo físico. **Los renders enlazados debajo corresponden al refinamiento anterior**, no a este último pulido. La revisión actual corresponde al usuario en su celular. Cambios preparados en Git preexistentes, incluido navegación, permanecen intactos; no se alteró el staging ni se hizo commit/push.

Refinamiento DEV de la base elegida por el usuario; acabado e ilustración pendientes de aprobación. No se crea otra HomeScreen. MAIN conserva Inicio actual, y Actual/A/B/Signal Flow permanecen como referencias.

## Comparar los dos tratamientos

En `flutter run -t lib/main_dev.dart -d edge`, entrar con la sesión mock, abrir el menú de ajustes DEV y elegir **C · Guardian Deck**. Reabrir ese mismo menú: ahora incluye **A · Ilustración lineal** y **B · Ilustración 2.5D**. Cambian únicamente la gráfica del módulo; vehículo, información, acciones y scroll no se reemplazan. A es la selección inicial de comparación, no una decisión artística aprobada. Hot Reload para revisar; Hot Restart si la sesión anterior no incorpora el campo de selección nuevo.

| A · Ilustración lineal | B · Ilustración 2.5D |
| --- | --- |
| Silueta vectorial de perfil inspirada en el HTML, ahora centrada y con todo el ancho disponible. | Vehículo nativo del Splash D, con sus colores y perspectiva aprobados, sobre un plano vial estático. |
| Lectura sobria y ligera, pocos trazos y buen contraste sobre Navy. | Mayor volumen y profundidad; mantiene continuidad con la identidad ilustrada del Login. |
| [Render Flutter a 390 × 844](guardian_390.png) | [Render Flutter a 320 × 844](guardian_320.png) |

Ambas son simbólicas. No representan exactamente marca/modelo, ubicación real, recorrido o monitoreo en vivo. No se implementan fotografías. Los renders usan datos ficticios de los mocks y dimensiones diferentes: sirven para composición/adaptación, no para una comparación A/B de tamaño idéntico; esa elección se hace en el selector DEV.

## Cambios de UI/UX

- Cabecera con isotipo y wordmark oficiales mediante el mismo `PremiumClosureBrandPainter` del fotograma final de Login, encuadrado sin editar geometría o colores. Se retira la línea Teal superior únicamente en Guardian. Ni Login ni Splash se modifican.
- Tarjeta Navy con identidad a ancho completo y gráfica central de 132 dp; sin vehículo arrinconado, textos superpuestos o una segunda tarjeta de estado. Marca/modelo y placa crecen con el escalado del sistema.
- Disponibilidad reportada y comunicación quedan dentro del pie del módulo, con jerarquía propia y anuncio semántico de cambios. `online` conserva exclusivamente el significado de comunicación, sin puntuación de salud.
- Red móvil, tecnología/registro reportado y GNSS/fix se consultan directamente en el contenido desplazable, sin desplegar. No se promete que todo esté dentro del primer viewport. Con texto grande se apilan.
- Un único desplegable secundario muestra voltaje en V, intensidad en dBm y presencia/ausencia reportada de microSD, únicamente cuando existen sus bloques/valores. Sin porcentajes, umbrales, autonomía ni diagnóstico agregado. Los fallbacks de los modelos siguen siendo una limitación conocida; no se amplía su contrato.
- Ubicación compacta sin mapa. No se infiere posición actual o última posición válida de datos insuficientes. La atención existente sigue por encima del módulo y del contenido secundario.
- Actividad reciente con rótulo, tinta Navy y contenedores de iconos suavemente rectangulares. Impactos usan colisión; avisos vistos usan visibilidad. Un reconocimiento personal no se representa como resolución del incidente. Se conserva filtro/orden/límite de tres y la clasificación existente. Los defaults de las otras pantallas no cambian.
- Se mantienen las transiciones existentes: distintivo 160 ms y expansión 180 ms, eliminadas con movimiento reducido. La ilustración y la marca son estáticas, con `RepaintBoundary`; no hay animación decorativa continua.

## Implementación y validación

`guardian_deck_refinement.dart` contiene las piezas locales; reutiliza los pintores nativos públicos de marca y vehículo sin modificar los archivos de Splash. La pieza anterior de Guardian se reemplaza localmente y su pintor sin consumidores se retira; el checkpoint previo sigue en Git. `HomeVisualPreview`/`DevNavigationReview` añaden una selección gráfica, no una ruta o variante completa. `HomeScreen` solo pasa esa selección presentacional.

Archivos afectados: `home_visual_preview.dart`, `home_screen.dart`, `premium_home_content.dart`, `signature_home_directions.dart`, nuevo `guardian_deck_refinement.dart`, `recent_alerts_preview.dart`, `dev_navigation_review.dart`, pruebas y documentación. Sin cambios de Providers, repositorios, Firebase, router, autenticación, AppTheme, Login, Splash o dependencias.

Resultados: **31 pruebas funcionales dirigidas satisfactorias y dos renders móviles**. La pasada conjunta inicial pasó 32 casos (30 funcionales + dos renders); posteriormente se añadió y pasó la prueba específica de iconos, sin repetir casos ya satisfactorios. Incluye ambas ilustraciones a 320/360/390 dp con texto 200 %, movimiento reducido, acceso por teclado, datos ausentes, error de eventos, reconocimiento, prioridad crítica y aislamiento MAIN. Análisis estático de los nueve Dart afectados: **sin incidencias**. El pintor anterior sin referencias se retiró tras el aviso del analizador.

El conector de navegador devolvió inventario vacío: no se inspeccionó Edge. Se inspeccionaron visualmente los **dos renders reales del árbol Flutter** enlazados arriba, con Manrope y Material Icons cargados desde recursos locales. Marca completa, ilustración centrada y adaptación sin invasión de la navegación. Los controles flotantes visibles son los del panel DEV. No se generan otras capturas. Estos renders no certifican rasterización web, TalkBack ni rendimiento en Android físico.

Para reproducir solo esos renders: `flutter test --no-pub -r expanded --dart-define=URBES_EXPORT_GUARDIAN=true test/guardian_visual_review_test.dart`. El test opcional usa el SDK local en `C:/development/flutter` para cargar Material Icons; en otra instalación pasar `--dart-define=URBES_FLUTTER_SDK=RUTA_DEL_SDK`. No cambia assets ni configuración de la aplicación. Sin el flag de exportación, ambos casos se omiten.

Siguen pendientes revisión humana del acabado y elección A/B, contraste/lectura en dispositivo y perfilado físico. No hay política nueva de frescura ni estados inventados. Sin commits ni push. Para revisar con mocks basta la app DEV local y Edge; SDA, bridge, celular físico, Internet y Firebase pueden permanecer apagados.
