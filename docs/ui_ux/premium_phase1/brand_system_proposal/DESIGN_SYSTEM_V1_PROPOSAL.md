# URBES Design System v1.0 — propuesta consolidada

16 de octubre de 2026. **Pendiente de revisión y aprobación humana.** Documentación y prototipo; no implementación Flutter. [Comparativa actual/propuesta](index.html) · [Tokens](TOKENS.md) · [Componentes](COMPONENTS.md) · [Accesibilidad](ACCESSIBILITY.md).

## Punto de partida y autoridad

Los seis incrementos Splash→Login fueron aprobados por el usuario en Android físico. Checkpoints: `fceba33` (1–4), `a5c4d53` (5) y `98f5689` (6). Se conservan D, las geometrías, recorrido, baliza, marca, cierre y destino del Login; `finalSceneZoom: 1.0`. La validación de esos incrementos no aprueba automáticamente la paleta global ni el refinamiento del formulario.

| Decisión | Estado comprobado |
|---|---|
| Isotipo U + pulso, colores originales del SVG | Seleccionado; no editar paths ni recolorear. Solo variante clara localizada en `motion_prototype_01/logo.svg`. |
| Composición isométrica y Variante D | Aprobadas en Flutter DEV, seis incrementos. No se rediseñan. |
| Reutilización del Login real y presentación opcional | Implementada y aprobada DEV; `_submit`, validadores y autenticación conservados. |
| Navy `#031B3B` como primario global | Propuesto; producción sigue usando `#1B2B48`. |
| Aqua interactivo, teal `#006D68`, semántica y densidad | Propuestos, no aprobados globalmente. |
| Manrope | Ya usada en Flutter y prototipos; ratificación de la escala premium pendiente. |
| Inicio, Alertas y Emergencia premium | Prototipos previos; aún no implementación aprobada. |
| Google, mapas, llamada, frescura y políticas de transporte | Decisiones/tareas funcionales separadas; este diseño no las resuelve. |

Fuentes recuperadas: `../REVIEW.md`, `../../../UI_UX_PHASE1_SPEC.md`, `../../../PREMIUM_SPLASH_LOGIN_FLUTTER_SPEC.md`, esta carpeta, `../composition_v3/`, `../motion_prototype_01/`, `lib/core/theme/`, `lib/widgets/`, `LoginScreen`, `HomeScreen`, `AlertsScreen`, `ActiveEmergencyScreen` y sus widgets. `docs/design_reference/DESIGN_SYSTEM.md` es referencia histórica con YAML y prosa divergentes: para el estado implementado prevalece el código. No se sobrescribe como si esta propuesta estuviera aprobada.

## Dirección y composición

La identidad se concentra en la escena aprobada del Login y una superficie protagonista del vehículo en Inicio. Alertas se lee por grupos; Emergencia por incidente, ubicación y alcance del acuse. El resto usa espacio, texto claro, divisores y feedback Material. No se repite una ilustración en cada pantalla ni se añade un dashboard de tarjetas equivalentes.

```text
Login                  Inicio                 Alertas                 Emergencia
marca y escena D        marca                  marca                   incidente y vehículo
título y descripción   saludo                 título y recepción      ubicación/calidad
correo / contraseña    vehículo protagonista  atención                tiempos
acceso                 disponibilidad SDA     informativos/técnicos   diagnóstico
                       métricas / ubicación   historial               acuse y alcance
                       acciones / 5 destinos  5 destinos              sin barra inferior
```

### Identidad y roles cromáticos

Recomendar Navy `#031B3B` como **único primario UI**, sustituyendo `#1B2B48` en roles equivalentes después de aprobación. El navy anterior puede permanecer en detalles artísticos de la escena; no se recolorea el SVG ni se trata como segundo primario.

Reservar Aqua `#14E0D3` para identidad, acentos sobre Navy o superficies con texto Navy. No usarlo como texto sobre blanco ni como único borde/foco. Proponer `#006D68` para vínculos, foco y acciones secundarias; selección `#CCF7F3` con texto Navy. Canvas `#F8F9FA`, superficie blanca, texto `#1B1B1E` y apoyo `#44474D`. Los fondos no se tiñen indiscriminadamente de aqua.

Verde, ámbar y coral identifican únicamente estados resueltos por los contratos existentes. Separar acento, texto y superficie. Desconocido/antiguo/sin datos usa neutros y explicación, sin inferir normalidad. Error de formulario es un rol UI independiente de incidente crítico, aunque comparta provisionalmente un tono accesible. El acuse de emergencia es una acción ordinaria de reconocimiento: no se vuelve rojo solo por estar en pantalla crítica. `CriticalButton` se reserva a operaciones urgentes existentes cuyo significado lo justifique.

### Tipografía

Mantener Manrope, disponible con OFL en `../assets/`, como única familia candidata. Evitar una nueva dependencia/fuente. Aprobar posteriormente cómo se suministra offline en producción: `AppTypography` usa actualmente Google Fonts y la escena contiene contornos propios del wordmark, no una segunda familia.

| Rol | Tamaño / línea | Peso | Uso |
|---|---|---:|---|
| Título Login y crítico | 32 / 40 | 800 | Bienvenida e incidente; crítico 26/32 cuando el ancho lo requiere, sin truncar. |
| Título pantalla | 28 / 34 | 800 | Inicio y Alertas. |
| Sección | 20 / 28 | 700 | Categorías y superficies protagonistas. |
| Cuerpo / control | 16 / 24 | 500 / 600 | Valores, campos, acciones. |
| Apoyo | 14 / 20 | 400 | Tiempos, ayuda y errores relevantes. |
| Etiqueta | 14 / 20 | 600 | Campos y estados. Sentence case; sin tracking ornamental. |
| Navegación | 12 / 16 | 600 | Cinco destinos con icono; texto escalable. |

El título Login nativo aprobado usa 32 con línea 1,3; la tabla es la escala global candidata, no permiso para cambiar su coreografía. No bajar fuentes para hacer caber contenido a 200 %. Texto del sistema, alto contraste y TalkBack deben revisarse en Android; el CSS no acredita ese comportamiento.

### Espacio, forma y adaptación

Conservar escala existente 4/8/16/24/32/48 y gutter 12. Margen general 20; Login conserva 24 en su artboard aprobado. Separación entre secciones 24–32; entre etiqueta/campo 8; campos 16–20 según ayuda/error. Las alturas mínimas crecen con texto: botón/campo ≥56 dp, objetivo táctil ≥48×48 dp. La propuesta no fija altura máxima a controles o mensajes.

Radios: 24 para superficie protagonista/diálogo, 16 para campos/botones, 12 auxiliares, 8 etiquetas y 4 detalles. Elevación ordinaria 0; 2 solo overlay candidato. Borde decorativo 1 px y control 1 px, foco/error 2 px; foco de teclado visible exterior 3 px en la muestra web. No sustituir borde funcional por sombra tenue. Aplicar los roles mediante `AppRadius`, `AppShadows` y tema existentes después de aprobación.

Ancho máximo 600, nunca ancho obligatorio. A 320–360, permitir apilado de métricas y títulos multilineales. Scroll común en Login con teclado conserva el encuadre de escena aprobado. En Emergencia, asegurar que las acciones no tapen contenido a 200 %; el diagnóstico queda secundario y desplazable. Sin reorganizar destinos o introducir una sexta rama.

### Iconografía y microinteracciones

Material Icons es la familia instalada. Proponer un criterio outline consistente: 24 dp general, 20 en campos/metadatos, 32 en estado protagonista, hit area 48. Mantener metáforas semánticas: correo, candado, ojo, vehículo, aviso, ubicación. El logo no es un icono operativo ni indicador de conexión.

Lucide se evalúa como **referencia de geometría**, con una retícula 24 y trazo óptico cercano a 1,8–2 px; los iconos del HTML son trazados locales existentes y pequeños símbolos propios, no una colección Lucide descargada. Recomendar inicialmente Material outline para evitar dependencia nueva. Si Material no alcanza coherencia suficiente, comparar un conjunto acotado antes de autorizar recursos/licencia; no mezclar bibliotecas dentro de la misma fila. [Guía oficial Lucide](https://lucide.dev/guide/).

Motion candidato: feedback 120 ms cúbica de salida, selección/cambio local 180 ms, entrada finita 240 ms cúbica de salida. Mantener respuesta nativa al toque inmediata; no retrasar navegación ni incidentes. Foco/error cambia borde y ayuda sin vibración, sacudida o salto de altura inesperado. Reducir movimiento elimina desplazamientos/pulsos decorativos, mantiene contenido y estado ocupado legibles. No imponer escalado a botones globalmente. D conserva sus tiempos específicos; 4440 ms no es un token de espera. No repetir entrada por teclado, actualización remota o reconstrucción.

## Auditoría por pantalla

| Pantalla | Qué cumple y se conserva | Inconsistencia y mejora propuesta | Reutilización y pendiente |
|---|---|---|---|
| Login | Escena/lockup D, scroll con teclado, único formulario, validadores, autofill y errores existentes. | Campos sin iconos; etiqueta en mayúsculas; jerarquía y foco por refinar. Correo/candado, etiquetas persistentes, borde accesible, ayuda y error asociados, ojo de 48 dp. | `LoginScreen`/`LoginFormParts`, `PrimaryButton`, tema de inputs. El ojo es una mejora de interacción futura que requiere aprobación; no está implementado en Flutter. Google pendiente funcional, sin botón. |
| Inicio | Componentes locales, Provider, cinco destinos, datos y acciones existentes. | Varias tarjetas blancas con mismo radio/sombra; afirmación global «operativo» más amplia que `online`. Vehículo protagonista, métricas/divisores y estado separado. | Evolucionar `VehicleSummaryCard`, `UrbesStatusCard`, indicadores, quick actions; mantener contactos. Copy de disponibilidad y frescura requiere revisión funcional separada. |
| Alertas | Clasificación actual en atención, informativos, técnicos e historial; acuse existente. | Densidad de metadatos, badges pequeños y detalles compitiendo con atención. Jerarquía tipográfica, tonos accesibles y tiempos separados. | `AlertCard`, secciones y `SectionHeader` locales/compartidos. No nueva búsqueda funcional; mostrar búsqueda solo en catálogo. |
| Emergencia | Prioridad/redirección y cierre, ubicación/calidad, diagnóstico y acuse actuales. | Urgencia repetida, coral con contraste insuficiente en usos, acciones no implementadas visibles. Cabecera estable, ubicación antes de diagnóstico y alcance de «Ya lo vi». | `ActiveEmergencyScreen`, `StatusPill`, botones y disposición existentes. Llamada/mapa no operativos se registran, no se activan. No countdown/cancelación desde app ni confirmación extra de acuse. |

Las maquetas son ejemplos independientes con un vehículo/SDA ficticios. En las comparativas Inicio/Alertas/Emergencia, la izquierda reconstruye estructura del código y la derecha evoluciona las propuestas HTML previas; no se inventa evidencia fotográfica de producción. El Login izquierdo es la captura propia de QA del Incremento 6 y su tipografía tiene las limitaciones documentadas allí. La cabecera de la propuesta recorta visualmente la captura nativa propia del cierre, sin alterar la escena aprobada. El prototipo no autentica ni implementa pantallas de producto.

## Decisiones para aprobación

| ID | Recomendación concreta | Estado |
|---|---|---|
| DS1 | Navy `#031B3B` único primario UI; Aqua intacto, teal `#006D68` para interacción accesible. | Pendiente. |
| DS2 | Pares semánticos de tokens; neutros para ausencia/antigüedad y error UI separado. | Pendiente. |
| DS3 | Manrope, escala y pesos anteriores; control offline de fuente antes de producción. | Pendiente. |
| DS4 | Espaciado/radios existentes, elevación mínima, Inicio con una superficie protagonista y Alertas con filas. | Pendiente. |
| DS5 | Material outline inicialmente; Lucide solo referencia sin dependencia. | Pendiente. |
| DS6 | Refinamiento Login, iconos y futura visibilidad de contraseña; conservar validación/Auth/escena D. | Pendiente; interacción del ojo requiere aprobación de implementación separada. |
| DS7 | Política motion 120/180/240 ms, atención estática, reducción de decoración y emergencia inmediata. | Pendiente; D ya aprobado no se reabre. |
| DS8 | Jerarquía de las cuatro pantallas y estrategia de reutilización sin nuevos shells o formularios. | Pendiente. |

**Fuera de estas aprobaciones:** Google Sign-In, destino de llamadas/mapas, frescura y políticas de origen; no se resuelven aprobando el Design System. Variantes oficiales oscura/monocromática del logo siguen pendientes de localizar/recibir. No hay tema oscuro aprobado.

## Plan Flutter posterior, no autorizado todavía

1. Ratificar DS1–DS8 y registrar la tabla aprobada, resolviendo el carácter histórico de `design_reference/DESIGN_SYSTEM.md` sin dos fuentes vigentes.
2. Evolucionar `AppColors`, `AppTypography`, `AppTheme`/`ThemeData` y temas de controles; pruebas de roles/contraste con captura DEV de referencia. No cambiar clasificadores ni datos.
3. Refinar un único consumidor: Login con sus campos reales. Aprobar por separado el ojo, estados/foco/teclado/autofill; conservar la presentación por defecto hasta autorizar activación. Sin Google ni cambios Auth.
4. Aplicar variantes a `PrimaryButton`, `GhostButton`, `CriticalButton`, `StatusPill`, `SectionHeader`; extraer algo nuevo solo ante dos consumidores equivalentes.
5. Inicio, luego Alertas: incrementos separados con snapshots, texto grande y regresión funcional. Resolver copy dependiente de contrato antes de cambiarlo.
6. Emergencia: incremento propio con pruebas de prioridad, `queued`, cierre, acuse, reducción de movimiento y ausencia de espera; validar acciones con sus tareas funcionales.
7. Perfilado físico en modo profile autorizado: UI/raster, teclado, scroll y actualizaciones. TalkBack, fuentes grandes y contraste contextual. Solo después decidir activación en producción.

Cada paso exige autorización posterior y revisión humana. Esta entrega se detiene en la propuesta del Design System.
