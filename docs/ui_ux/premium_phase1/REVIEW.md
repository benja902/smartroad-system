# URBES Premium Redesign — Fase 1

> Documento histórico de la propuesta visual 01. Para decisiones vigentes de marca y componentes, consultar la [propuesta consolidada DS v1.0](brand_system_proposal/DESIGN_SYSTEM_V1_PROPOSAL.md), todavía pendiente de aprobación. Los seis incrementos Splash→Login D ya fueron aprobados en Flutter DEV; las referencias siguientes al escudo provisional no reemplazan el isotipo oficial seleccionado.

Estado: propuesta visual 01 para revisión. Diseño y prototipado exclusivamente; no aprueba D1–D3 globales ni modifica Flutter. La referencia de marca de Brand Intro 01 sigue siendo provisional y el usuario informa evaluación visual positiva. No se declara rendimiento medido.

## Abrir y revisar

Abrir `index.html` en Chrome o Edge. Es autónomo: HTML/CSS/JavaScript sin framework, fuente local y sin backend. La galería permite comparar las cuatro pantallas; los botones del estudio abren una pantalla interactiva y sus escenarios. Cada pantalla de la galería representa un momento independiente, no cuatro vistas simultáneas de una misma sesión.

[Abrir prototipo](index.html) · [Comparativa de las cuatro pantallas](previews/overview.png) · [Estudio de revisión](previews/studio.png).

Capturas individuales: [Login](previews/login.png), [Inicio navy](previews/home.png), [Inicio claro](previews/home-light.png), [Alertas](previews/alerts.png), [Emergencia](previews/emergency.png). Casos de revisión: [Inicio sin datos](previews/home-no-data.png), [grave diferido](previews/alerts-deferred.png), [SOS sin ubicación](previews/emergency-no-location.png), [texto 200 %](previews/emergency-text-200.png) y [ubicación tras desplazamiento con texto 200 %](previews/emergency-text-200-location.png).

No introducir datos reales: el login es una simulación local, sin solicitudes de autenticación ni almacenamiento. Todo el contenido representa al propietario de un único vehículo y un SDA ficticios. Los tres destinos sin maqueta mantienen su posición visual, pero no se desarrollan en este prototipo.

Recorrido sugerido: comparar la galería → elegir Inicio y alternar navy/claro → probar los escenarios de datos → revisar Alertas y el fallo/éxito de «Ya lo vi» → simular llegada crítica durante carga → revisar SOS/ubicación/hora desconocida → ampliar texto y reducir movimiento. Las listas y los contenidos de cada teléfono se desplazan de forma independiente. En Login basta completar ambos campos con texto ficticio no vacío; la simulación conserva la validación mínima actual, no autentica credenciales.

Para observar el prototipo: SDA apagado, bridge detenido, app Flutter y celular innecesarios. Internet no es necesario; Firebase y Emulator no se utilizan ni se modifican. No hay que apagar el proyecto Firebase.

## Diagnóstico actualizado

Evidencia: código de Login, Inicio, Alertas, Emergencia, tema, widgets y clasificación vigentes; especificación UI/UX y ambos pilotos. Las capturas disponibles en `docs/design_reference/` son históricas; no se presentan como capturas actuales. La validación visual de esta entrega es del nuevo HTML, no del frontend Flutter en el Moto.

| Área | Hallazgo en la implementación | Conservar / transformar |
| --- | --- | --- |
| Identidad | Navy y Manrope dan una base reconocible; Login usa un escudo Material genérico y las cabeceras repiten símbolos. | Conservar base; usar el escudo provisional de Brand Intro y una cabecera más quieta. |
| Tipografía | Escala existente coherente; mayúsculas y etiquetas de 12 dp compiten con contenido. | Manrope; pesos 500/650/750, sentence case, 14–16 para información útil. |
| Composición | Muchas tarjetas con igual radio y sombra producen poca diferencia entre estado, vehículo, ubicación y diagnóstico. | Una superficie protagonista en Inicio; filas y divisores para datos; elevación solo en el marco del estudio. |
| Login | Formulario preservable; bloque central poco diferenciado, etiquetas en mayúsculas. | Campos y validación; composición de marca propia, etiquetas persistentes y visibilidad de contraseña como propuesta UI. |
| Inicio | Bienvenida afirma funcionamiento correcto incluso sin datos; `online` alimenta varias afirmaciones amplias. | Proponer texto limitado al dato recibido. No deducir disponibilidad total ni frescura de `online`. Su integración exige revisión funcional posterior. |
| Indicadores | El piloto ya mejora texto grande y evita truncados. Batería/señal/ubicación siguen con peso similar. | Mantener adaptación; jerarquizar disponibilidad y procedencia antes de métricas. |
| Alertas | Clasificación en cuatro grupos es útil; tarjetas y metadatos densos, acciones de acuse y detalles con jerarquías discutibles. | Conservar grupos y precedencia; destacar atención, usar filas para registros y mostrar el acuse como acción personal. |
| Emergencia | Título, badge, banner y textos repiten urgencia; mapa placeholder y diagnóstico consumen espacio antes de acciones. | Título y calidad de ubicación primero; diagnóstico desplegable del propietario; sin navegación inferior. |
| Acciones pendientes | Mapa y llamada tienen callbacks vacíos; detalles son un placeholder. | No ofrecerlos como funcionalidades disponibles. En las maquetas el mapa aparece deshabilitado con razón; llamada y detalle se omiten como acciones. |
| Acuse | El texto «marcar como atendido» puede interpretarse como ayuda prestada. | Propuesta «Ya lo vi», con explicación de que no cancela ni solicita ayuda. La clasificación interna no cambia. |
| Color | Verde, ámbar y coral actuales no ofrecen por sí mismos texto ordinario blanco accesible. | Conservar acentos reconocibles; separar acento de texto semántico oscuro y superficie tonal. Véase matriz verificable. |
| Navegación | `NavigationBar` y `StatefulShellRoute` ya conservan cinco ramas. | Misma distribución y nombres; indicador discreto. No diseñar módulos pendientes. |
| Estados | Las pantallas leen listas y valores; no todos exponen carga/error/reintento explícitos. | Maquetar variantes de presentación; no afirmar que el proveedor actual tenga esos contratos. No añadir reintento sin operación real. |
| Movimiento | Piloto finito y reducción de movimiento adecuados; banner de atención mantiene pulso/contador continuo. | Conservar continuidad; propuesta estática para atención, feedback por acción. Cambiar el banner Flutter será tarea posterior autorizada. |
| Rendimiento | Repetición DEV fluida informada por el usuario; hay evidencia de pausa en arranque frío, sin traza causal. | No justificar refactorización global. Medir Flutter antes de optimizar; el HTML no acredita FPS Android. |

## Plan visual y revisión previa a construir

Dirección: **Silent Guardian, más esencial**. El motivo propio es una carretera que se vuelve protección, heredado de Brand Intro; en Inicio se expresa como una silueta vectorial de vehículo sobre una línea de camino, sin simular un mapa, recorrido, velocidad ni conexión en tiempo real.

Base compacta: navy `#1B2B48`, fondo frío `#F4F6FA`, blanco `#FFFFFF`, secundario `#526078`, verde de texto `#176B50`, crítico de texto `#B52F34`. El ámbar de texto `#80520A` queda reservado a atención. La propuesta no sustituye aún `AppColors`.

Manrope única, alineación izquierda, títulos 28/34 y crítico 32/38 (base 28 en una maqueta de hasta 340 px de ancho); cuerpo 15/22; controles 16/24; metadatos 14/20; etiquetas de navegación 12/16. Todas esas bases responden al multiplicador de texto del estudio. Radios 24 protagonista, 16 controles, 12 superficie auxiliar; divisores ligeros. Espaciado 4/8/16/24/32/48, margen móvil 20. Área táctil de los controles activos de la maqueta de al menos 48 px; equivalencia Android a validar en Flutter.

Esquema inicial y revisión:

```text
Login                 Inicio                Alertas               Emergencia
marca + camino        marca + saludo        marca + título        urgencia estable
bienvenida            aviso si corresponde  atención              tipo y vehículo
formulario            vehículo protagonista informativos          ubicación y calidad
acceso                estado e indicadores  estado técnico        tiempos y diagnóstico
                      ubicación             historial             acuse + alcance
                      cinco destinos        cinco destinos        sin barra inferior
```

Autocrítica previa: un dashboard de tarjetas iguales o cuatro héroes navy sería genérico y diluiría la urgencia. Se revisa el plan: el navy ocupa solo la superficie del vehículo en Inicio; Login usa espacio y marca lineal; Alertas se organiza por registros; Emergencia usa una cabecera coral tonal, nunca una pantalla roja intermitente. La silueta del auto es decorativa, no una nueva funcionalidad ni una señal de estado.

## Componentes y tokens candidatos

Son nombres descriptivos para consolidar en los archivos actuales después de aprobación; no una segunda arquitectura visual.

| Pieza | Propuesta | Integración futura |
| --- | --- | --- |
| Marca | Escudo vectorial provisional, mismo lenguaje de Brand Intro. | Recurso compartido cuando se apruebe identidad; no imponer otra intro. |
| Cabecera | Marca a izquierda, avatar no interactivo cuando no exista destino concreto. | Cabeceras actuales, evitando extraer abstracciones sin necesidad. |
| Formulario | Etiqueta persistente, foco 2 px navy, error local estable, mostrar contraseña. | Login y `InputDecorationTheme`; sin sustituir autenticación. |
| Botones | Primario navy, secundario tonal; feedback inmediato, foco visible, estado de envío. | `PrimaryButton`/`GhostButton` y tema Material existentes. |
| Estado | Icono + palabra; texto semántico oscuro en fondo suave. | `StatusPill`; no deducir estado de la falta de datos. |
| Vehículo | Una superficie navy con nombre, placa y dibujo; estado recibido aparte. | `VehicleSummaryCard` y contenido de Inicio; no añadir vehículo ni telemetría. |
| Indicadores | Una agrupación con divisores, valores y unidades; ausencia explícita. | `DeviceIndicatorsGrid`; sin renombrar contratos. |
| Atención | Franja ámbar estática y acuse; sin pulso ni cuenta regresiva. | `AttentionBanner`/tarjeta de alerta después de autorización. |
| Ubicación | Coordenadas + calidad + contexto temporal; mapa deshabilitado con explicación. | Componente de ubicación actual; política de frescura sigue en Fase 5. |
| Emergencia | Título, vehículo, ubicación y acuse en orden de lectura; diagnóstico desplegable. | Pantalla crítica; mantener router y clasificación. |
| Barra inferior | Cinco destinos y selección tonal discreta. | `NavigationBar` actual; no cambiar `goBranch`. |

Acentos históricos `#2ECC71`, `#F39C12` y `#E74C3C` se pueden mantener como detalles no textuales; se proponen tokens separados para texto/fondo. Los valores de contraste se calculan con el script local, no se asumen por apariencia. El foco y la iconografía relevante también requieren comprobación contextual.

| Par comprobado | Ratio calculado |
| --- | --- |
| Navy / blanco | 14,13:1 |
| Texto secundario / fondo frío | 5,88:1 |
| Verde de texto / tonal verde | 5,78:1 |
| Ámbar de texto / tonal ámbar | 6,15:1 |
| Crítico de texto / tonal crítico | 5,54:1 |
| Etiqueta deshabilitada / fondo deshabilitado | 5,41:1 |
| Texto secundario del vehículo / navy | 9,24:1 |
| Texto de origen / fondo crítico | 7,70:1 |

Esta matriz verifica los pares indicados, no certifica toda la accesibilidad del producto. Blanco sobre los tres acentos históricos queda por debajo de 4,5:1 según el mismo cálculo; no se propone como texto ordinario.

## Motion y microinteracciones

| Pantalla / acción | HTML demostrable | Propuesta Flutter posterior / límite |
| --- | --- | --- |
| Login | Una entrada de 240 ms, 6 px, opacidad 0,94–1; foco inmediato; visibilidad de contraseña; errores sin mover toda la pantalla. | Timeline finito del piloto, sin retrasar submit; revisar teclado/autofill nativos. |
| Acceso | Submit ficticio navega sin demora artificial; carga controlada desde el estudio. | Estados reales del envío; no prolongar carga por estética ni inventar confirmación. |
| Inicio | Primera entrada del encabezado/vehículo 240 ms; al volver de Alertas no se repite; scroll se conserva. | Conservar montaje y estado de ramas actuales. |
| Selección inferior | Color/indicador en 160 ms, acción inmediata. | `NavigationBar` Material 160–180 ms; no copiar CSS literalmente. |
| Datos | Cambio de escenario sin animación global, conservando el desplazamiento; datos anteriores no se convierten en actuales. | Actualización puntual; no justificar optimización Provider sin perfilado. |
| Alertas | Feedback de acuse; fallo conserva registro; éxito ficticio lo pasa a historial según clasificación vigente. | Esperar confirmación de la fuente autorizada. No implementar acuse optimista. |
| Emergencia | Interrupción inmediata; sin transición de entrada o salida que retenga información. | Redirección existente prioritaria; mismo comportamiento con intro/carga activa. |
| Diagnóstico | Desplegable nativo del navegador sin animación de altura. | Expansión breve opcional 160–200 ms, manteniendo lectura y scroll. |
| Pulsación | Fondo y escala máxima 0,985 durante 100 ms, sin esperar para ejecutar. | Feedback Material; feedback háptico solo tras validación y decisión posterior. |
| Movimiento reducido | CSS del sistema y control del estudio eliminan entrada/transiciones; spinner queda estático. | `MediaQuery.disableAnimationsOf`; no ocultar estados al reducir movimiento. |

Con texto grande la explicación del acuse pasa al contenido desplazable y permanece vinculada al botón mediante `aria-describedby`; la acción fija no ocupa media pantalla. En 320 × 640 y texto 200 % se necesita desplazamiento para leer todo el incidente y su calidad de ubicación. No se fuerza una altura fija ni se trunca el contenido para hacerlo caber.

Curva candidata de respuesta: `cubic-bezier(0.2, 0, 0, 1)`; salida no decorativa. No animaciones continuas salvo indicador de carga mientras ese escenario esté seleccionado. La intro de marca no se recrea en HTML: se conserva el piloto Flutter aprobado como referencia, sin duplicar ni afirmar equivalencia de motores.

## Contratos preservados en los ejemplos

- Precedencia idéntica al clasificador actual: técnico/desconocido; cancelación; cancelado; reconocido; diferido; crítico; moderado; informativo. Un `queued:true` grave no abre Emergencia.
- SOS expresa solicitud manual; choque/volcadura expresan detección automática. No se muestran cronómetros del SDA ni cancelación desde la app.
- «Ya lo vi» simula confirmación personal, no atención de rescate, envío de ayuda ni modificación del incidente global. El fallo simulado conserva el aviso.
- Ubicación ausente no afirma que el equipo nunca haya conseguido GNSS. Sin fix muestra última posición conocida; la calidad del ejemplo pertenece al evento, no a seguimiento en vivo.
- Hora del evento, recepción y último estado del SDA tienen etiquetas distintas. El escenario de dato anterior no establece un umbral de caducidad.
- Carga/error/vacío son maquetas; si el proveedor no diferencia esos estados, su contrato debe resolverse en el chat funcional antes de integrarlos. Sin botón de reintento ficticio.
- Mapas, llamadas y detalles pendientes no se convierten en acciones reales. Los módulos no definidos no se prototipan anticipadamente.

## Decisiones para revisar

1. Aprobar esta dirección navy / superficies frías / vehículo protagonista, o solicitar otra composición. Alternativa acotada en el estudio: Inicio claro, para comparar presencia de marca con la misma estructura y datos.
2. Mantener Manrope y aprobar la escala/pesos propuestos; no se añade otra fuente Flutter.
3. Aprobar textos semánticos oscuros separados de los acentos históricos y validar la matriz por uso real.
4. Aprobar el orden de Emergencia, diagnóstico desplegable y copy «Ya lo vi». Se propone omitir llamada/detalle hasta que sean funcionalidades reales; mapa visible pero explícitamente deshabilitado.
5. Aprobar movimiento sobrio sin pulso de atención y selección discreta; medir antes de adoptar en Flutter.
6. Aprobar o ajustar la silueta vectorial del vehículo y el uso del escudo provisional. Ninguno queda como identidad definitiva por esta entrega.

## Implementación posterior, un incremento por vez

1. Revisión visual del HTML, decisiones anteriores y muestras con texto grande; registrar aprobaciones específicas sin marcar tareas funcionales completadas.
2. Tokens de contraste y campos/botones compartidos en los archivos actuales. Verificar consumidores y capturas de regresión; no cambiar todos los componentes a la vez.
3. Login con autenticación existente y tests de validación/carga/error; probar teclado y TalkBack.
4. Inicio con los datos y políticas ya aprobados por el chat funcional. No corregir disponibilidad/frescura dentro del cambio visual.
5. Alertas, preservando clasificador, orden, cancelación, `queued` y estado personal confirmado.
6. Emergencia, regresiones de disparo inmediato, cancelación remota, acuse y navegación; sin llamada/mapa inventados.
7. Profile físico autorizado en Moto G9 Power y revisión de accesibilidad real. Comparar UI/raster antes/después; no declarar 60 FPS por el HTML.

Skill usada: `frontend-design`. No se encontró una skill específica Flutter/motion entre las skills instaladas listadas y los directorios consultados. Codex puede integrar con widgets nativos y documentación oficial; una skill futura se debe revisar antes de instalarla, y no es requisito para estas maquetas. No se añadieron dependencias Flutter.

## Validación y límites

Completado localmente el 13 de octubre de 2026, en Windows con Node v24.15.0 y Chrome headless 155.0.8059.40:

- 4/4 pruebas Node: precedencia de fixtures, ausencia/calidad/tiempos, ocho pares de contraste y ausencia de APIs de red/almacenamiento del prototipo.
- 32/32 comprobaciones de navegador: formulario y visibilidad de contraseña; acceso ficticio; scroll y regreso sin repetir entrada; sin datos/dato anterior; acuse fallido y confirmado; diferido y desconocido; interrupción crítica de carga; SOS manual; ubicación ausente/antigua; hora desconocida; movimiento reducido; cuatro pantallas a 320 × 640 y texto 200 % sin desborde horizontal, con controles activos de al menos 48 px; mapa deshabilitado y ausencia de acciones de llamada/cancelación. [Resultado detallado](previews/validation.json).
- Apertura directa `file://` comprobada: no requiere instalar paquetes ni ejecutar servidor. El verificador usa un servidor transitorio limitado a esta carpeta y enlazado a `127.0.0.1`; lo cierra al terminar y elimina únicamente su perfil temporal de Chrome.
- 12 capturas PNG generadas, incluida comparativa, estudio y variantes. Inspección visual de composición; se corrigió el ancho impuesto por Chrome headless y el espacio del acuse con texto grande. Las capturas son renderizados del HTML, no de Flutter ni del Motorola.
- Sintaxis JavaScript comprobada; sin cambios en Flutter, dependencias, rutas, repositorios ni reglas. No se ejecutó la suite Flutter porque no se modificó código Dart. Los tres archivos locales del trabajo funcional de contactos no se editaron desde esta tarea.

Bloqueos de esta entrega: ninguno. Pendiente para una fase autorizada posterior: revisión visual del usuario, decisiones de marca/contraste/copy, lector de pantalla real y teclado móvil, orientación/escalado nativo, adaptación de estados a contratos funcionales aprobados y profile en el Moto. Las animaciones CSS y las comprobaciones DOM no acreditan rendimiento Flutter ni conformidad integral de accesibilidad. Sin commit ni push en esta fase.

Comandos de verificación (no requieren SDA, celular, bridge ni Firebase):

```powershell
node --test docs/ui_ux/premium_phase1/tests/fixtures.test.cjs
node docs/ui_ux/premium_phase1/verify.mjs
```

El segundo comando usa la ubicación habitual de Chrome en Windows; se puede indicar otro Chromium mediante `URBES_BROWSER`. Las validaciones se ejecutaron con acceso local elevado, conforme a la preferencia del usuario.

## Archivos creados

Todos están aislados bajo `docs/ui_ux/premium_phase1/`:

| Archivo o grupo | Propósito |
| --- | --- |
| `index.html` | Estudio navegable, galería y vectores propios de marca, vehículo e iconos. |
| `styles.css` | Tokens candidatos, cuatro composiciones, adaptación y motion reducido. |
| `prototype.js` | Interacciones ficticias y controles del estudio, sin backend ni persistencia. |
| `fixtures.js` | Ejemplos y helpers exclusivos del prototipo; nunca se importan en Flutter. |
| `assets/` | Manrope local, OFL y FONTLOG oficiales. No se modifica la fuente ni se añade a Flutter. |
| `tests/` y `verify.mjs` | Pruebas sin dependencias externas, verificador de navegador y exportación reproducible. |
| `previews/` | Capturas PNG observables y resultado JSON de la comprobación del navegador. |
| `REVIEW.md` | Diagnóstico, propuesta de componentes, motion, decisiones y plan incremental. |

Referencias: [accesibilidad Flutter](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling), [rendimiento Flutter](https://docs.flutter.dev/perf/best-practices), [perfilado](https://docs.flutter.dev/perf/ui-performance), [Manrope y licencia](https://github.com/google/fonts/tree/main/ofl/manrope). Los archivos de licencia y FONTLOG acompañan la copia local de la fuente; la fuente se usa solo en el prototipo.
