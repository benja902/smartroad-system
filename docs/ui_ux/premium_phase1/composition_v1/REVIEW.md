# URBES — Splash y Login · composiciones v1

14 de octubre de 2026. **Propuesta para revisión; sin aprobación para implementar.**

[Abrir láminas y storyboards](index.html) · [Comparativa PNG](comparison.png) · [Storyboard A PNG](storyboard-a.png) · [Storyboard B PNG](storyboard-b.png) · [Referencias suministradas](../references/URBES_REFERENCIAS_ANIMACION_v1/ANIMATION_REFERENCES.md).

## Alcance y evidencia

La auditoría diferencial aceptada es el punto de partida. Se conserva el prototipo anterior y Brand Intro 01. Esta carpeta añade únicamente documentos, geometría vectorial propia, láminas estáticas y muestras internas de referencia. No se editan Flutter, autenticación, router, repositorios, recursos Android, dependencias ni el HTML premium anterior. La página nueva no contiene JavaScript, formularios activos, llamadas de red ni almacenamiento.

Se leyeron `ANIMATION_REFERENCES.md`, `AGENTS.md`, los antecedentes de Brand Intro, los tokens vigentes y la implementación del Login auditada en la etapa anterior. Se inspeccionaron visualmente los cinco archivos de `fotogramas/`.

También se verificaron los tres MP4 con `ffprobe` y se examinaron muestras decodificadas con FFmpeg, sin instalar herramientas:

| Video | Metadatos verificados | Muestreo inspeccionado | Observación directa |
|---|---|---|---|
| Beeway | 19,866667 s; 576 × 776; 30 fps | Primeros 8 s, 2 muestras/s | Personaje/suelo, edificios, teléfono, vehículo y marcador aparecen sucesivamente. Se superponen escena saliente y Login. |
| Parcel | 17,733333 s; 576 × 718; 30 fps | Primeros 8 s, 2 muestras/s | Cambian orientación del vehículo y geometría del escenario; marca convive con movimiento. Se desvanece hacia Login. |
| Skyward | 16,8 s; 576 × 776; 30 fps | Primeros 8 s y ventana desde 9,8 s de 4 s, 2 muestras/s | Motivo de avión/trayectoria en Splash, superposición hacia Login, paso del avión por cabecera y reutilización del motivo durante carga. |

[Beeway muestreado](evidence/01_beeway-sampled.jpg) · [Parcel muestreado](evidence/02_parcel-sampled.jpg) · [Skyward muestreado](evidence/03_skyward-sampled.jpg) · [Carga Skyward](evidence/03_skyward-loading-sampled.jpg).

Las hojas se leen de izquierda a derecha y de arriba abajo. Son evidencia interna derivada de los videos entregados, no assets de URBES. El primer conjunto representa aproximadamente 0–7,5 s a intervalos de 0,5 s; la ventana de carga es aproximada por búsqueda/selección temporal de FFmpeg. No se atribuye precisión de un fotograma a estos tiempos.

**No verificado:** reproducción continua a velocidad real, easing exacto, interpolación entre muestras, aceleraciones, movimiento relativo preciso vehículo/cámara, posible profundidad 3D, sincronización de audio, rendimiento de las apps originales ni tecnología de implementación. Hay pista de audio, pero no se escuchó. No se inspeccionó cada fotograma ni el resto completo de los tres videos. El código visible alrededor de los simuladores no se utiliza para deducir técnicas. Las observaciones temporales más detalladas del documento siguen siendo estimaciones aportadas por el usuario.

## Dirección y autocrítica

Perspectiva **cenital plana**, vehículo de URBES y contexto vial abstracto. Se evita mezclar el auto cenital con edificios isométricos o con el vehículo lateral de Inicio. La profundidad se expresa mediante superposición, superficies tonales y detalles de trazos, sin motor 3D, blur ni efectos luminosos.

Se reutilizan navy `#1B2B48`, fondo `#F8F9FA`, blanco `#FFFFFF`, texto `#1B1B1E`, secundario `#44474D` y borde `#C5C6CE`. Las capas decorativas derivan del navy mediante opacidad; no se introduce una nueva paleta global. Manrope se carga desde el recurso local del prototipo anterior. En las láminas: título 32, cuerpo 15, controles 16, etiquetas 14; márgenes 24 de exploración visual frente a los 20 vigentes, pendientes de aprobar. Radios de campos y botones 16, altura 56. No se modifican tokens existentes.

El color de error oscuro `#B52F34` se toma de la propuesta premium anterior; sigue siendo candidato, no cambio aprobado de `AppColors`.

Autocrítica: una ciudad completa como Beeway alejaría la propuesta del motivo carretera→protección y elevaría el coste sin mejorar el acceso. Se reduce el entorno a parcelas, señalización y vegetación cenital abstracta. Tampoco se usa verde decorativo que pudiera interpretarse como estado operativo. La ilustración no representa un mapa real, seguimiento en vivo, ruta calculada, cobertura ni conexión confirmada.

## Dos alternativas

### A · La ruta se construye

[Composición A](a-3.svg). Inspiración: aparición por capas descrita y observada en Beeway.

Composición de 390 × 844: escena vial en una ventana aproximada de x=15–375, y=251–571. Nombre vectorial debajo. Las parcelas y grupos vegetales equilibran el camino; el auto aporta escala y el escudo cierra la lectura. Cámara fija. El orden propuesto es superficie→entorno→carretera→vehículo→escudo/nodos→nombre.

La composición usa piezas separadas para que el revelado pueda superponerse brevemente, sin una sucesión rígida de esperas. El vehículo recorre un tramo corto; la riqueza viene principalmente de cómo se construye la escena.

Ventaja: mayor riqueza ilustrativa y lectura espacial. Riesgo: añadir capas sin jerarquía; deben retirarse las que compitan con vehículo/escudo. Es la recomendación inicial para evaluar la dirección de composición principal, sin aprobarla de antemano.

### B · El vehículo guía

[Composición B](b-3.svg). Inspiración: cambio de rumbo y protagonismo del recorrido observado en Parcel.

La misma geometría vial se amplía a escala 1,16, con origen aproximado x=−14, y=220. El corredor ocupa más altura y el entorno se retira durante el recorrido. Una línea navy señala el tramo ilustrado recorrido; no es telemetría. El vehículo inicia orientado hacia arriba, toma una curva hacia la derecha y después vuelve hacia arriba. Escudo y nombre estabilizan el cierre. La escena no gira: en URBES se propone comprobar el rumbo del auto con una cámara fija.

Ventaja: narrativa de movimiento más clara. Riesgo: pequeños fallos en tangentes, pivote o velocidad se vuelven protagonistas. No se puede asegurar su calidad con estas poses estáticas.

La hoja de rumbo en `index.html` muestra cinco poses, no un algoritmo ni una animación. Antes de codificar se debe revisar una prueba de movimiento continua que compruebe el segundo giro, la velocidad y el ángulo del vehículo.

## Login común

[Login propuesto](login-ready.svg). Una sola composición reutiliza ruta, entorno, vehículo y escudo de ambas alternativas. El mundo ilustrado queda anclado aproximadamente en x=42, y=66, escala=0,85. El vehículo termina en el tramo superior, con rumbo arriba. El escudo conserva su geometría maestra de Brand Intro 01.

Título «Bienvenido.» y copy del prototipo anterior; campos, etiquetas persistentes y botón con la jerarquía existente. El nombre URBES queda en cabecera, evitando repetirlo en el título. No se agregan registro, acceso social, recuperación, permisos ni funcionalidades nuevas.

Los campos y el botón son dibujos en las láminas, no componentes implementados. En una futura variante DEV se conservarán controladores, validadores, mensajes, autofill, submit y navegación existentes. `PrimaryButton` y `InputDecorationTheme` siguen siendo los puntos de reutilización. La visibilidad de contraseña existe en el HTML anterior, **no** en `LoginScreen` Flutter: su integración sería una mejora UI por autorizar; la referencia no prueba que esté implementada.

| Estado | Propuesta visual y garantía |
|---|---|
| Inicial | Ilustración estática tras entrega. Formulario visible sin un recorrido perpetuo. |
| Teclado | [Variante compacta](login-keyboard.svg): reducir/eliminar espacio decorativo y permitir scroll; no encoger texto ni bloquear campos. Dibujo de teclado solo contextual. |
| Error | [Variante error](login-error.svg): conservar datos/foco, mensaje legible, sin repetir intro. Reservar espacio cuando sea posible; aceptar scroll si crece el mensaje. |
| Envío | [Variante carga](login-loading.svg): «Ingresando…» inmediato y bloqueo de doble envío según lógica existente. Sin bucle del vehículo ni espera artificial; si termina rápido, se deja actuar al router. |
| Movimiento reducido | Omitir completamente Splash; mostrar directamente Login estático si ese es el destino. La imagen común conserva identidad sin depender del movimiento. |
| Sesión abierta | No mostrar Login. Retirar escena sobre el destino existente. No forzar sesión mock cerrada ni cambiar comportamiento real. |

## Storyboard y coordinación

Los storyboards A/B de `index.html` contienen seis fotogramas. Son anclajes de composición: **no prueban una interpolación continua ni equivalencia con Flutter**.

| Momento | A: capas | B: recorrido | Qué continúa |
|---|---|---|---|
| 1. Arranque | Carretera estática vigente | Igual | Fondo y vector Android DEV, 160 dp, centrado. |
| 2. Construcción | Entorno y camino aparecen por capas | Aparece corredor ampliado | Lenguaje del camino; nueva escena todavía experimental. |
| 3. Vehículo | Tramo corto sobre escena construida | Inicio del recorrido y primer giro | Mismo vehículo, pivote y perspectiva. |
| 4. Marca | Escudo/nodos y wordmark legibles | Marca convive con tramo horizontal | Escudo y wordmark provisionales de Brand Intro. |
| 5. Entrega | Una escena se reduce a la cabecera | Final del segundo giro y reducción al mismo anclaje | Misma ruta, vehículo y escudo; sin dibujar dos copias superpuestas. |
| 6. Login | Título/formulario visibles | Idéntico | La escena queda en reposo. |

**Entrega exacta propuesta:** en el paso 4→5 cambia la transformación del grupo ilustrado, desde (15,251,1) en A o (−14,220,1,16) en B hasta (42,66,0,85). En B se retira el trazo de recorrido y aparece el entorno común durante esa entrega. El auto concluye en (254,105) dentro del mundo local. El wordmark de trazos desaparece y el nombre tipográfico de cabecera aparece: no se pretende deformar un lettering hasta Manrope. El título y formulario usan una entrada breve solo cuando quedan descubiertos; si el usuario omite la escena, se presentan directamente.

**Límite de reutilización:** se conserva el vector nativo inicial, pero la unión del paso 1→2 está pendiente de una prueba de movimiento. Se propone desvanecer la pequeña carretera inicial mientras emerge la escena amplia; no se promete un morph exacto aún. Estas alternativas preservan el concepto carretera/protección y las geometrías del escudo/nombre, pero no reproducen el morph carretera→escudo actual. Si se quiere conservar literalmente ese morph, debe decidirse antes de la prueba de movimiento porque cambia el montaje. No se sustituye el Splash actual.

Montajes candidatos para una etapa de motion autorizada: A cercano a 1900 ms efectivos y B exploratorio de 2300 ms efectivos. Comparar también B a 1900 ms antes de aceptar una prolongación. Los tiempos externos no se trasladan a URBES. El arranque nativo no se incluye en estas duraciones. No se añade ninguna espera a autenticación ni se obliga a completar la escena.

| Montaje | Construcción | Vehículo y cierre de marca | Entrega al destino |
|---|---|---|---|
| A, candidato 1900 ms | 0–300 ms | 300–1500 ms, fases superpuestas y cierre legible | 1500–1900 ms |
| B, candidato 2300 ms | 0–300 ms | 300–1850 ms, dos giros y cierre legible | 1850–2300 ms |

No son tiempos aprobados ni descripción de una animación ya ejecutada. La futura prueba debe incluir reposo de marca y evitar que todos los recursos compitan por atención.

## Matriz diferencial

| Pieza actual | Tratamiento | Impacto / pendiente |
|---|---|---|
| Host DEV y controles de interrupción | Conservar | No reconstruir ciclo de vida ni router. |
| Vector inicial Android | Conservar | Enlace a escena amplia pendiente de validar. |
| Escudo, nodos y wordmark | Conservar/adaptar | Se reutiliza geometría Flutter, provisional. Unificar HTML previo después de aprobar. |
| Morph carretera→escudo | Falta decidir | No está representado literalmente en las nuevas láminas; actual queda intacto. |
| Carretera vertical y auto | Mejorar en variante futura | Nueva ruta con curvas, vehículo refinado y orientación documentada. |
| Escudo Material del Login Flutter | Sustituir solo en variante futura aprobada | Mantener formulario; usar motivo común en ilustración. |
| `ScreenEntrance` | Conservar/coordinación futura | Iniciar la entrada cuando sea visible; no usarlo para toda la escena. |
| Paleta/Manrope/componentes | Conservar base | Escala, margen 24 y error oscuro son candidatos; D1–D3 abiertos. |
| HTML premium anterior | Conservar íntegro | Nueva carpeta independiente para comparación. |

## Recursos y herramientas

Geometría nueva original: eje vial con dos curvas, capas de entorno abstracto y refinamiento del vehículo cenital. Geometría heredada: escudo, nodos y wordmark de `BrandIntroPainter`. No se usan assets de las apps externas ni se busca material adicional.

SVG es el formato de estas propuestas editables y estáticas. El generador Python utiliza únicamente biblioteca estándar y escribe dentro de esta carpeta. La revisión web carga Manrope local; los SVG abiertos individualmente pueden usar una fuente de sustitución porque no llevan la fuente incrustada. La composición de referencia tipográfica es el HTML renderizado.

Flutter nativo sigue siendo la hipótesis de implementación adecuada: `CustomPainter` y timeline finito para escena; componentes actuales para formulario. SVG no implica instalar `flutter_svg`. Rive/Lottie no se justifican por estas láminas; reconsiderarlos solo si la prueba aprobada exige capacidades o un flujo de autoría que compensen runtime y mantenimiento. No se ha instalado ni elegido ninguna dependencia.

## Garantías y validación futura

- Prioridad crítica: cerrar overlay y cualquier entrega visual inmediatamente, sin esperar fases; el router vigente decide destino. Las láminas documentan esta garantía, no la prueban de nuevo.
- Omitir por toque, movimiento reducido o segundo plano: terminar escena; al volver no se reinicia. Mantener la acción semántica única del host y ocultar semántica de contenido tapado.
- No alterar autenticación, proveedores, Firebase, bridge ni firmware. Las futuras variantes de presentación se seleccionan exclusivamente DEV; el Login compartido no se modifica dentro de esta entrega.
- Medir profile después de autorizar: arranque frío/caliente, UI/raster, fotogramas fuera del presupuesto, duración efectiva/real y memoria tras repeticiones. El avance acotado actual puede prolongar la duración real y no elimina bloqueos de arranque.
- Revisar la entrega a 320 × 640, texto 200 %, escala máxima del equipo, teclado y TalkBack. Las láminas SVG escalan como dibujos; no demuestran reflow Flutter ni objetivos táctiles reales.
- Contraste mínimo objetivo 4,5:1 texto normal; 3:1 texto grande y controles relevantes. Las líneas tenues son decorativas. Si cambian de rol se deberán medir; no presentar trazos decorativos como estado legible.
- Mantener primeras pruebas dirigidas de `brand_intro_test.dart` y `motion_pilot_test.dart` cuando se autorice código; no ejecutar suites costosas ahora.

## Decisiones para la siguiente autorización

Elegir A, B o una combinación acotada; aprobar/ajustar perspectiva cenital y densidad del entorno; decidir si se exige conservar literalmente el morph; revisar Login común y las variantes. Después, autorizar por separado una prueba de movimiento de presentación, antes de llevarla a Flutter.

Estas decisiones son de diseño. No aprueban D1–D3 para toda la aplicación, despliegues ni uso físico. No se realizó commit ni push.

## Validación de esta entrega

- 16 SVG analizados como XML sin errores; 4 páginas HTML revisadas por estructura, enlaces locales y anclas. No hay formularios activos ni scripts en las páginas nuevas.
- Comparativa y ambos storyboards exportados con Chrome headless y examinados visualmente: composiciones, textos y orden completos en sus láminas de escritorio. Se diferenció B retirando entorno y destacando el tramo recorrido.
- El primer intento de Chrome falló por GPU; otro intento no terminó y se detuvo. La exportación final usó renderizado sin GPU y `--no-sandbox` exclusivamente sobre estas páginas locales propias. Los perfiles temporales creados para exportar se eliminaron. Esto no acredita rendimiento gráfico de la aplicación.
- Las variantes teclado/error/carga están propuestas en SVG/HTML; no se verificaron con teclado móvil ni TalkBack real. No se hicieron pruebas Flutter, emulador, compilación ni perfilado físico.
- Los cambios de esta tarea están limitados a `composition_v1/`. Los archivos ya preparados por otros trabajos, el prototipo premium previo y las referencias suministradas se conservaron.

Para revisar: SDA apagado, bridge detenido, app Flutter/celular innecesarios, Internet innecesario. Firebase real y Emulator no se utilizan; no hace falta apagar el proyecto Firebase.
