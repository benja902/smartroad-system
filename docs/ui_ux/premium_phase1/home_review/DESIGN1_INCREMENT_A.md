# Diseño 1 — Mapa sutil + Ruta y Estudio · Incremento A

Estado: presentación Flutter DEV para revisión humana. No consolida MAIN ni implementa los incrementos B/C. La referencia es la imagen facilitada por el usuario, no sus datos demostrativos.

## Composición y reutilización

- Cabecera con el lockup vectorial oficial ya utilizado en Login, saludo de sesión y subtítulo «Tu vehículo y sus últimos datos». Perfil abre la ruta existente mediante su callback. Sin fotografía de usuario ficticia.
- Cartografía abstracta propia con `CustomPainter`, estática, excluida de semántica y sin ubicación, marcador o conexión con telemetría. No se añade SDK de mapas.
- Hero Navy con identidad del vehículo real, placa, carretera de estudio e iluminación Aqua suave. Disponibilidad y comunicación reutilizan `_SdaCopy`: no equivalen a salud integral; época cero no se presenta como fecha válida.
- Un Bento de tres indicadores: tecnología/registro móvil, fix GNSS y voltaje de batería del SDA. Valores opcionales ausentes se muestran neutralmente. La disposición depende de la medición de textos y espacio disponible; no se apila automáticamente por el porcentaje de texto. Si no cabe, pasa a vertical sin truncar información.
- Posición compacta: coordenadas únicamente con el fix reportado, sin afirmar actualidad o última posición válida conservada. No se atribuye `lastSeen` a la hora de la posición. No hay flecha o acción cartográfica ficticia.
- Actividad reutiliza `RecentAlertsPreview`, su clasificación y límite de tres registros. «Ver todas» acompaña a la cabecera con su acción real a Alertas; con texto grande puede pasar a la siguiente línea. El banner y sus callbacks se reciben de `HomeScreen`, antes del hero. No se fabrican eventos «SDA en línea» para parecerse a la imagen.
- Feedback y foco estándar de los controles existentes; expansión técnica breve, desactivada con movimiento reducido. Sin nuevas animaciones de entrada o efectos constantes.

## Recurso pendiente: fidelidad del hero incompleta

La revisión de recursos SVG/PNG/JPG/WebP en `docs` y `lib` encontró ilustraciones vectoriales, geometría nativa del vehículo y capturas completas de interfaces. No hay un render 3D independiente adecuado al Diseño 1. Las capturas y referencias externas no se usan como assets de interfaz.

**Respaldo temporal:** geometría 2.5D del automóvil de D, estática, sobre carretera abstracta independiente. No se cambia su geometría ni el Splash. Esta ilustración no sustituye ni da por aprobado el render 3D premium.

**Imagen a preparar:** vehículo genérico estilizado, sin emblemas, marca ni placa legible, vista tres cuartos frontal, proporciones coherentes y contorno independiente con transparencia. Propuesta de entrega: PNG/WebP alfa de unos 1600 × 900 px, vehículo ocupando el encuadre con margen y sombra de contacto separable, luz fría suave compatible con Navy/Aqua. No debe incluir textos, tarjeta, estado, fondo de pantalla o controles. Confirmar perspectiva, derechos y licencia antes de incorporarlo. La carretera seguirá siendo una capa independiente. No se ha buscado, comprado ni generado una imagen definitiva.

Faltan por tanto el volumen, materiales, iluminación y presencia del render de referencia. La revisión visual debe distinguir esta brecha de la aprobación de composición. La batería y nombre del vehículo se verán distintos si así lo indican los datos; no se replica el 12.4 V ni la Hilux de la maqueta.

## Alcance y comparación

En el selector DEV existente elegir **Diseño 1 · Ruta y Estudio (DEV)**. Guardian Deck sigue siendo la selección inicial y el diseño compartido de MAIN. Las alternativas históricas se conservan. No se crea otra pantalla funcional ni otro panel.

La barra mantiene sus cinco destinos y Pill Active. El acceso superior a Perfil coexiste temporalmente con su pestaña; retirar la pestaña y extender la cabecera a las otras secciones corresponde al Incremento B, todavía no implementado.

No hay cambios en Providers, repositorios, Firebase, router, autenticación, Login, Splash, tema global o dependencias. El informe de `alerts_review` pendiente previamente permanece intacto. El checkpoint local posterior fue autorizado por el usuario; no incluye ese informe ni el recurso `auto.webp`, todavía sin referencias en la implementación. Sin push.

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
