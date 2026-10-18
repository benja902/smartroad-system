# Diseño 1 — Mapa sutil + Ruta y Estudio · Incremento A

Estado: presentación Flutter DEV para revisión humana. No consolida MAIN ni implementa los incrementos B/C. La referencia es la imagen facilitada por el usuario, no sus datos demostrativos.

## Composición y reutilización

- Cabecera con el lockup vectorial oficial ya utilizado en Login, saludo de sesión y subtítulo «Tu vehículo y sus últimos datos». Perfil abre la ruta existente mediante su callback. Sin fotografía de usuario ficticia.
- Cartografía abstracta propia con `CustomPainter`, estática, excluida de semántica y sin ubicación, marcador o conexión con telemetría. No se añade SDK de mapas.
- Hero Navy con identidad del vehículo real, placa, carretera de estudio e iluminación Aqua suave. Integra `auto.webp` aportado por el usuario como ilustración temporal de revisión. Disponibilidad y comunicación reutilizan `_SdaCopy`: no equivalen a salud integral; época cero no se presenta como fecha válida.
- Un Bento de tres indicadores: tecnología/registro móvil, fix GNSS y voltaje de batería del SDA. Valores opcionales ausentes se muestran neutralmente. La disposición depende de la medición de textos y espacio disponible; no se apila automáticamente por el porcentaje de texto. Si no cabe, pasa a vertical sin truncar información.
- Posición compacta: coordenadas únicamente con el fix reportado, sin afirmar actualidad o última posición válida conservada. No se atribuye `lastSeen` a la hora de la posición. No hay flecha o acción cartográfica ficticia.
- Actividad reutiliza `RecentAlertsPreview`, su clasificación y límite de tres registros. «Ver todas» acompaña a la cabecera con su acción real a Alertas; con texto grande puede pasar a la siguiente línea. El banner y sus callbacks se reciben de `HomeScreen`, antes del hero. No se fabrican eventos «SDA en línea» para parecerse a la imagen.
- Feedback y foco estándar de los controles existentes; expansión técnica breve, desactivada con movimiento reducido. Sin nuevas animaciones de entrada o efectos constantes.

## Integración de vehículo y fondo de estudio — recurso de revisión

Se utiliza el archivo independiente `auto.webp` proporcionado por el usuario (1000 × 558 px, RGBA, con transparencia, unos 46 KB), sin editar sus píxeles ni recolorear su carrocería. Se registra su ruta exacta en `pubspec.yaml`, sin duplicar el archivo ni añadir paquetes. Este registro incorpora el recurso al bundle; la presentación que lo consume continúa seleccionable exclusivamente en DEV. MAIN sigue mostrando Guardian Deck.

El fondo mantiene Navy y un halo frío suave, con carretera abstracta, trazos Aqua contenidos y sombra de apoyo dibujados en un `CustomPainter` estático. El WebP se coloca en una capa independiente con `BoxFit.contain`, sin deformación ni recorte, en un área de proporción 2,2:1. Su decodificación se limita al ancho necesario según densidad, con máximo de 1000 px. No se utilizan filtros para teñir el auto, blur animado o efectos continuos. El estado SDA dispone de un fondo Navy casi opaco para proteger sus textos. Ante un error de carga se conserva el respaldo vectorial nativo existente.

**Pendientes:** `auto.webp` representa un deportivo reconocible, no el vehículo descrito por el Provider. Su uso se limita a evaluar la composición como ilustración simbólica; no es una fotografía del vehículo asociado ni un recurso final aprobado. Procedencia y derechos no documentados: confirmar antes de consolidarlo para producción. El recurso definitivo recomendado sigue siendo un vehículo genérico sin emblemas, de perspectiva e iluminación compatibles, con transparencia. La imagen no debe incluir textos, tarjeta, estado o controles. No se ha buscado, comprado ni generado otro recurso.

La separación entre fondo, carretera, sombra, imagen y datos permite cambiar de vehículo sin rediseñar el módulo. La composición se inspeccionó con el automóvil azul disponible; no se ha comprobado físicamente ni validado con recursos blancos, negros o rojos. No se promete contraste automático para cualquier imagen arbitraria. La batería, nombre y placa conservan sus datos del Provider. No se añaden flechas a Vehículo o posición mientras sus destinos útiles sigan pendientes.

## Alcance y comparación

En el selector DEV existente elegir **Diseño 1 · Ruta y Estudio (DEV)**. Guardian Deck sigue siendo la selección inicial y el diseño compartido de MAIN. Las alternativas históricas se conservan. No se crea otra pantalla funcional ni otro panel.

La barra mantiene sus cinco destinos y Pill Active. El acceso superior a Perfil coexiste temporalmente con su pestaña; retirar la pestaña y extender la cabecera a las otras secciones corresponde al Incremento B, todavía no implementado.

No hay cambios en Providers, repositorios, Firebase, router, autenticación, Login, Splash, tema global o dependencias. El informe de `alerts_review` pendiente previamente permanece intacto. El checkpoint local posterior fue autorizado por el usuario; no incluye ese informe ni el recurso `auto.webp`, todavía sin referencias en la implementación. Sin push.

La integración del WebP descrita arriba es posterior al checkpoint `8c6d3b4`, que conservó la versión vectorial. Este refinamiento sí referencia `auto.webp` y su checkpoint local posterior fue autorizado por el usuario. No avanza a B/C ni realiza push. `chevi.webp` permanece como candidato local sin integrar y queda fuera de este checkpoint.

## Validación

Pruebas dirigidas: aislamiento DEV/MAIN, acceso a Perfil y cierre de sesión, cinco destinos, actualizaciones mock de disponibilidad/red/GNSS, reconocimiento moderado, prioridad crítica, datos ausentes/época cero/error de eventos, expansión y acción por teclado; 320/360/390 dp con texto 100/200 % y movimiento reducido.

Resultado: 44 pruebas funcionales/de presentación distintas aprobadas entre las ejecuciones dirigidas (34 de Inicio previo, 9 de Diseño 1 y 1 del arranque DEV real/cierre de sesión). Se corrigieron dos fallos del arnés: selección de una opción que ahora requiere desplazar el menú y solicitud de foco desde un contexto sin ese ancestro. Se repitieron las comprobaciones afectadas. Tras integrar la acción de cabecera se verificaron nuevamente los 9 casos nuevos y 4 regresiones relevantes; tras ajustar el ancho del Bento se repitieron los 2 casos de 360 dp. Análisis estático de 8 archivos sin incidencias; `git diff --check` satisfactorio.

La inspección reutiliza el render de pruebas Flutter existente con `URBES_EXPORT_STUDIO=true`: dos imágenes propias a [390 × 844](design1_390.png) y [320 × 844](design1_320.png), ambas comprobadas. Detectó pintura de carretera fuera del área ilustrada, corregida con recorte antes de la captura final, y alineación del Bento vertical, también corregida. Los 2 renders finales pasan sin excepciones. No se abrió Edge ni se utilizó hardware físico. No constituye perfilado Android.

Comandos principales: `flutter test --no-pub -r expanded test/route_studio_home_test.dart test/home_visual_preview_test.dart`; filtro posterior en esos archivos y `test/navigation_visual_preview_test.dart` con `--name 'Design 1|production ignores|DEV starts|Guardian impact|Real DEV startup'`; exportación con `flutter test --no-pub -r expanded --dart-define=URBES_EXPORT_STUDIO=true test/guardian_visual_review_test.dart`.

Revisión humana: ejecutar `flutter run -t lib/main_dev.dart -d edge`, acceder con el mock habitual y seleccionar Diseño 1 desde el botón de ajustes visuales. Usar Hot Reload. Para esta revisión DEV no se necesitan SDA, bridge ni Firebase real; pueden permanecer apagados/desconectados. App de prueba encendida. Internet solo si la configuración local necesita cargar fuentes; las pruebas automatizadas no usan servicios reales.

Detenerse tras el Incremento A: faltan aprobación humana de composición y preparación del render. No avanzar automáticamente a navegación de cuatro destinos ni a consolidación MAIN.

### Diagnóstico solicitado de distribución en Android

El selector DEV incorpora «Diagnóstico de tamaño · Bento» cuando está seleccionado Diseño 1. Desactivado inicialmente, muestra bajo los indicadores una lectura seleccionable de ventana lógica, MediaQuery, ancho interior real (incluye el descuento de padding y bordes), ancho por columna, densidad y tamaño efectivo de texto para la base 14. El porcentaje mostrado corresponde a esa base tipográfica, no presupone escalado lineal del sistema.

La captura aportada por el usuario confirmó ventana lógica de 484 × 1054,8 dp, interior de 414 dp y texto base 14 escalado a 18,2 (130 %). El criterio inicial forzaba vertical por superar 17, aun teniendo espacio. Esa regla y el umbral fijo de 270 dp se han sustituido por medición de contenido.

Cada columna recibe un tercio del espacio restante tras los dos separadores de 18 dp. `TextPainter` comprueba las mismas cadenas y estilos que se renderizan, con dirección, locale y `TextScaler` efectivos: hasta dos líneas de etiqueta, tres de valor y tres de detalle. Si algún indicador necesita más espacio, se conserva la disposición vertical, sin recortar texto ni reducir la preferencia de accesibilidad. La medida se descarta tras usarla; no hay animación ni mediciones de servicios. El diagnóstico explica ahora si caben los textos, no si se superó un porcentaje fijo.

Validación dirigida: 16 pruebas de presentación, datos, diagnóstico y accesibilidad, incluida la combinación 484 dp/130 % con tres columnas, pantallas de 320/360/390 dp y texto al 200 %. Los tests usan la fuente Ahem del entorno de pruebas, por lo que otros puntos de cambio dependen de la fuente real: no se promete un ancho universal. La lectura opcional permite comprobarlo en el teléfono. No se usa hardware físico, no se modifican preferencias de accesibilidad ni se registra información de sesión o del SDA. MAIN permanece intacto.

El usuario confirmó después que el problema de recarga web se resolvió y que el Bento funciona correctamente en su celular. Los cambios estructurales del diagnóstico pueden requerir Hot Restart (`R`), en lugar de Hot Reload, o una nueva ejecución si se utiliza profile. Esta confirmación no sustituye la preparación y revisión pendiente del render 3D.

### Validación del refinamiento del hero

Se añaden tres pruebas de decodificación real del WebP a 320 dp, 390 dp con texto al 200 % y 484 dp al 130 %: imagen cargada, sin tinte, `BoxFit.contain` y sin recurrir al respaldo. El arnés usa la fuente local para no depender de red al esperar la decodificación. Se reutiliza el exportador visual existente, que ahora espera explícitamente la carga de la imagen antes de capturar. Las vistas `design1_390.png` y `design1_320.png` se actualizan y se inspeccionan. Sin nueva página de revisión, servicios reales o hardware físico. Es necesario reiniciar la ejecución Flutter al incorporar la nueva declaración de asset; Hot Reload por sí solo puede no reconstruir el bundle.

Resultado del refinamiento: 19 pruebas dirigidas y 2 renders aprobados. Análisis estático dirigido sin incidencias. No se ha perfilado el recurso en Android físico; falta revisión humana del hero y de su ilustración definitiva.
