# Contraste y accesibilidad — propuesta v1.0

**Pendiente de aprobación.** Los valores se calculan en `build.py` desde `tokens.json`, con luminancia sRGB y decisiones sobre el ratio sin redondear. `contrast.json` contiene los pares medidos; `tokens.js` alimenta la tabla de la página. No se certifica la accesibilidad completa de Android con este cálculo.

## Criterios y uso

Texto ordinario ≥4,5:1; texto grande ≥3:1 según la definición WCAG, no por considerar una etiqueta «importante». Iconos y límites necesarios para identificar controles/estados ≥3:1 frente a colores adyacentes. Los colores semitransparentes se evalúan tras componerlos sobre su fondo, no como hex aislados. [W3C: contraste de texto](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html), [contraste no textual](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).

El logo tiene tratamiento de marca; la excepción de logotipos no se extiende a botones, textos o foco. Aqua original sobre blanco se conserva en el SVG y no se reutiliza para indicadores funcionales aislados. El borde decorativo no identifica por sí solo el campo: usar `border.control`, foco teal y error oscuro. Deshabilitado está exento del umbral WCAG correspondiente, pero se propone legibilidad suficiente y motivo cuando sea relevante.

Los ejemplos incluyen tanto pares candidatos que deben cumplir como pares históricos restringidos que deben detectarse: blanco sobre verde/ámbar/coral anteriores y Aqua/borde decorativo sobre blanco. No se maquillan como aprobados por conservar colores de marca. La tabla completa presenta valores y objetivos; no deduce que todo uso del acento sea incorrecto, sino que esos pares no sirven para esa función/tamaño.

| Par medido | Ratio | Aplicación |
|---|---:|---|
| Navy de marca / blanco | 17,16:1 | Texto/acción principal. |
| Teal interactivo / blanco | 6,20:1 | Texto interactivo, foco e iconos. |
| Borde funcional / blanco | 4,47:1 | Cumple 3:1 para identificar campo; no se usa como texto ordinario. |
| Error UI oscuro / blanco | 6,14:1 | Mensajes y borde de error. |
| Aqua original / blanco | 1,66:1 | Restringido; no texto ni foco funcional aislado. |
| Coral anterior / blanco | 3,82:1 | Insuficiente para texto ordinario blanco. |
| Verde anterior / blanco | 2,10:1 | Insuficiente para texto ordinario blanco. |
| Ámbar anterior / blanco | 2,19:1 | Insuficiente para texto ordinario blanco. |
| Borde decorativo / blanco | 1,70:1 | No identifica el campo por sí solo. |

Resultado reproducible: 31 pares medidos, 26 cumplen el objetivo asignado y cinco se registran como usos restringidos. Un fallo histórico es un hallazgo de auditoría, no una recomendación de uso en la candidata.

## Matriz de revisión

| Área | Propuesta / comprobación web | Validación Android posterior |
|---|---|---|
| Foco | Teal visible con borde y anillo exterior; no depender de sombra/Aqua. | Teclado externo y TalkBack, orden y restauración de foco. |
| Campos | Etiqueta persistente, icono decorativo, error enlazado; ejemplo de ojo con nombre/estado accesibles. | Semántica real, autofill, copiar/pegar, teclado e inicio/fin de edición. |
| Texto | Selector 100/150/200 %; sin truncar títulos/acciones; scroll interno. | Escala máxima del sistema y pantallas 320/360/390 dp; no encoger texto para encajar. |
| Toque | Icono 20/24, hit area ≥48; campo/botón mínimo 56, crecimiento permitido. | Medidas dp reales, separación y acceso sin precisión fina. |
| Estado | Icono + texto; desconocido distinto de operativo; error distinto de emergencia. | Fuente contractual y anuncio de cambios relevantes sin saturar TalkBack. |
| Movimiento | Preferencia del sistema y checkbox eliminan animaciones/transiciones decorativas. | Respuesta inmediata y garantías D/segundo plano/emergencia ya existentes. |
| Emergencia | Contenido visible aun con lectura auxiliar fallida; sin intermitencia ni countdown. | Prioridad real, foco inicial, texto grande y controles sin cubrir información. |
| Navegación | Cinco destinos sin añadir funciones; nombres conservados. | Selección anunciada, `goBranch` sin regresiones. |

Las imágenes de evidencia son rasterizadas: el selector de texto no puede ampliar su tipografía de forma semántica. La izquierda de Login sirve como referencia visual; la derecha usa texto HTML escalable. Las reconstrucciones de las otras tres pantallas no son snapshots de Flutter y no acreditan comportamiento nativo.

## Rendimiento y límites

La revisión usa recursos locales y no llama servicios. No se ejecutan pruebas Flutter ni se utiliza hardware en esta tarea documental. Las pruebas de navegador verifican recursos, selectores, aislamiento de acciones, IDs, estados, ausencia de overflow de página y reducción de movimiento; eso no prueba TalkBack, autofill, FPS o rasterización Android.

Para implementación posterior: conservar widgets Material accesibles, reconstrucciones localizadas y recursos preparados fuera de ticks. Medir UI/raster con presupuesto según frecuencia real (16,7 ms a 60 Hz, 8,3 ms a 120 Hz), sin afirmar que la red responde en ese tiempo. Evitar blur, grandes opacidades y animaciones continuas sin motivo. [Guía de accesibilidad Flutter](https://docs.flutter.dev/ui/accessibility).
