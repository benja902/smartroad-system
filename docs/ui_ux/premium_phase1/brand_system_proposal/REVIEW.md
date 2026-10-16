# Marca, tokens y componentes — propuesta provisional

15 de octubre de 2026. **Design System v1.0 NO aprobado.** Complementa la fase premium y el Motion Prototype 01; no los sustituye ni modifica la animación de marca.

[Comparativa visual interactiva](index.html) · [Inventario y mapa](COMPONENTS.md) · [Tokens candidatos](tokens.json) · [Contraste calculado](contrast.json) · [Borrador principal](../../../UI_UX_PHASE1_SPEC.md).

## Qué comparar

Seleccionar Login, Inicio, Alertas o Emergencia. Ambas columnas usan las mismas composiciones del HTML premium anterior y los mismos datos ficticios. Se conserva la jerarquía ya explorada; esta entrega es una **comparación de roles cromáticos**, no una afirmación de que el rediseño completo se reduzca a cambiar colores. La calidad premium sigue dependiendo de espacio, contenido, ilustración, estados y respuesta inmediata.

La columna anterior usa los colores del **prototipo HTML** (`#1B2B48`, fondo `#F4F6FA`, secundario `#526078`), no una captura actual de Flutter. La candidata usa Brand Navy como primario de interfaz, fondos `#F8F9FA`/blanco y secundario `#44474D`. Logo nuevo y escena estática de Login son iguales en ambas columnas para aislar el efecto de la paleta. No se modifica el SVG, no se ejecuta la intro ni se altera su timeline.

La sección de componentes permite examinar feedback de pulsación/foco, deshabilitado, envío y pares semánticos. Las acciones de las pantallas comparadas están deshabilitadas técnicamente pero muestran su tratamiento visual ordinario para comparar colores; el estado deshabilitado se muestra explícitamente en el banco de componentes. Sus botones solo confirman interacción local. No hay autenticación, escrituras, navegación de producto ni servicios reales.

El estudio reutiliza fixtures, composición, CSS y dibujo existentes. Es un artefacto de revisión bajo documentación, con una página generada y sin framework; no es una segunda aplicación ni una nueva arquitectura Flutter permanente.

## Dirección cromática razonada

- **Un primario:** `#031B3B` sustituiría a `#1B2B48` en roles equivalentes de interfaz si se aprueba. El navy anterior solo permanece en la columna histórica y en detalles de ilustración previamente aprobados con rol artístico explícito, no como segundo primario UI.
- **Marca intacta:** `#14E0D3` se mantiene en el SVG. Puede aportar detalles sobre navy o rellenos con texto oscuro. No se usa como texto claro sobre blanco ni como único borde/foco funcional.
- **Interacción accesible:** se explora `#006D68` para foco/texto y `#CCF7F3` para selección/superficie tonal. Son derivados de rol para la interfaz, no una modificación del logo ni valores finales de marca.
- **Semántica:** verde, ámbar y coral se reservan a estados confirmados por contratos. Acentos históricos pueden conservarse; texto y superficie se separan en tonos accesibles. Ausencia/antigüedad/desconocido permanecen neutros.
- **Error UI:** rol separado de severidad, aunque comparta provisionalmente un par cromático accesible. Error de Auth/lectura nunca se clasifica como incidente crítico.

## Contraste y límites

Quince pares se calculan con luminancia relativa sRGB. Resultados destacados:

| Par | Ratio | Consecuencia |
|---|---|---|
| Blanco / navy anterior | 14,13:1 | Base anterior ya ofrece buen contraste. |
| Blanco / Brand Navy | 17,16:1 | Más contraste y coherencia con el logo; no demuestra por sí solo mejor composición. |
| Aqua original / blanco | 1,66:1 | Insuficiente para texto ordinario y límites funcionales; no usarlo como única indicación de foco o selección. |
| Aqua original / Brand Navy | 10,32:1 | Uso viable en este par; verificar tamaño/rol contextual. |

El tono derivado, borde de control y los pares semánticos se incluyen en `contrast.json`; satisfacen sus objetivos numéricos indicados. El borde decorativo `#C5C6CE` no se trata como borde funcional suficiente: la candidata usa `#75777E` para campos. Un logo no debe convertirse en control sin revisar etiqueta, foco y contraste del control completo. [Criterio W3C de contraste no textual](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).

Esto no certifica todos los estados, semitransparencias, iconos, superposiciones ni accesibilidad Flutter. Texto grande, teclado, TalkBack y perfilado Android siguen pendientes de su etapa autorizada. En el estudio el control de texto permite 100/150/200 %; sigue siendo una aproximación CSS al escalado nativo.

## Tokens y conexión con el código existente

`tokens.json` es un registro **documental provisional** consumido solo por este estudio. La futura fuente de ejecución continuará siendo `lib/core/theme/` y `AppTheme`/`ThemeData`; no se propone importar este JSON en la app ni mantener dos sistemas.

| Familia | Propuesta | Integración futura |
|---|---|---|
| Color | Marca, acción, texto, superficie, borde, foco, deshabilitado y estados separados | `AppColors`, `ColorScheme`, temas de componentes; conservar roles de incidente explícitos. |
| Tipografía | Manrope; título 28/34, crítico 32/40, sección 20/28, cuerpo 16/24, apoyo 14/20, navegación 12/16 | `AppTypography` y `TextTheme`; escalado del sistema, no truncado de información relevante. |
| Espacio | 4/8/16/24/32/48; margen 20, gutter 12, máximo 600 | `AppSpacing` actual. |
| Forma | 24 protagonista, 16 control, 12 auxiliar; 8/4 por densidad | `AppRadius` actual, sin todas las superficies en tarjeta. |
| Elevación | 0 ordinaria; 2 candidata para overlay | `AppShadows`/tema; no sombra/glow animado. |
| Iconos | Material existente, 24 visual, objetivo táctil ≥48 | Iconografía existente; etiqueta cuando sea necesaria. Logo es recurso de marca separado. |
| Movimiento | Respuesta 120 ms, selección 180, entrada 240, cambio local 180; curvas sobrias | Reutilizar feedback Material y `ScreenEntrance`; no crear motor global. |

Roles de motion: respuesta inmediata al evento; selección con duración candidata, sin retrasar cambio de rama; entrada solo cuando se ve; actualización de datos sin animar toda la pantalla; emergencia sin demora decorativa; movimiento reducido elimina decoración conservando estados legibles. El pulso del logo sigue estático. La intro actual de 3800 ms queda **intacta y fuera de los tokens genéricos**: no se hereda esa duración para botones o navegación.

Flutter permite centralizar estilos mediante tema y temas de controles; la responsabilidad del widget específico se mantiene local. [Documentación de temas](https://docs.flutter.dev/cookbook/design/themes). Separar frecuencias de cambio, evitar trabajo repetido y contener efectos costosos orienta la propuesta; no implica que exista un problema de rendimiento demostrado. [Buenas prácticas Flutter](https://docs.flutter.dev/perf/best-practices).

## Variantes de identidad disponibles

Se encontró un SVG suministrado para fondos claros: `motion_prototype_01/logo.svg`. Se conserva y referencia sin filtros CSS, cambios de paths ni colores. En la tarjeta navy se coloca sobre una pequeña superficie blanca provisional para conservar legibilidad; no pretende sustituir la variante oficial oscura. Las versiones oficiales oscura y monocromática se registran como recursos pendientes de recibir/localizar; no se crean recoloreando esta versión. No se declara un tema oscuro aprobado.

## Decisiones pendientes

1. Aprobar Brand Navy como único primario UI; decidir alcance de migración de roles, sin sustituir colores de estados.
2. Aprobar uso de Aqua original y derivados de interacción. Revisar foco, selección, botones y tamaño mínimo del logo en contexto.
3. Confirmar Manrope, escala, densidad y uso de superficies/divisores; revisar texto 200 % y casos de teclado/errores.
4. Aprobar separación acento/texto/superficie semánticos y jerarquía de acciones. Las políticas funcionales y estados no definidos continúan en sus especificaciones vigentes.
5. Revisar mapa de componentes, mantener piezas locales y autorizar cualquier extracción solo con consumidores reales.
6. Recibir variantes oficiales de logo oscuras/monocromáticas y comprobar su uso; no simularlas con el SVG claro.
7. Revisar motion por componente y luego autorizar un incremento Flutter separado. Aprobar este documento no aprueba automáticamente código ni Design System v1.0.

## Validación y condiciones

Se calculan 15 pares mediante el script local `build.py` (biblioteca estándar). La comparación reutiliza recursos locales y no requiere dependencias nuevas. `preserved-files.json` registra los hashes de los archivos de animación y logo para comprobar su conservación. No se ejecutan tests Flutter ni hardware.

`node verify.mjs` pasa **18 comprobaciones locales de navegador**: cuatro pares, recursos cargados, controles sin operación funcional, roles de primario/foco/borde, escena estática, IDs únicos, tabla de contraste, selectores, ausencia de desbordamiento horizontal de página a 320 px y texto 200 %, y reducción de movimiento. Comprueba SHA-256 de los seis archivos protegidos de Motion Prototype 01 sin cambios. [Resultado reproducible](browser-validation.json). Capturas inspeccionadas: [Login](login.png), [Inicio](inicio.png), [Alertas](alertas.png), [Emergencia](emergencia.png). La comprobación de ancho no garantiza ausencia de recortes internos ni sustituye una revisión completa de texto grande/TalkBack en Android.

Para revisar: **SDA apagado, bridge detenido, app/celular e Internet innecesarios**. Firebase real y Emulator no se utilizan; no hace falta apagar el proyecto Firebase. Sin commit ni push.
