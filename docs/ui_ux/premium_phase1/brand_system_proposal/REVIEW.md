# Design System v1.0 · revisión consolidada

16 de octubre de 2026. **Propuesta pendiente de aprobación humana.** Los seis incrementos D Splash→Login están aprobados en Flutter DEV y conservados en Git. Esa aprobación no se extiende al tema global ni al refinamiento del formulario.

[Comparativa visual](index.html) · [Propuesta y decisiones](DESIGN_SYSTEM_V1_PROPOSAL.md) · [Tokens](TOKENS.md) · [Inventario/mapa](COMPONENTS.md) · [Accesibilidad](ACCESSIBILITY.md).

## Cómo revisar

La misma página incorpora **Actual / propuesta refinada** como comparación predeterminada y conserva **Paletas históricas**. Seleccionar Login, Inicio, Alertas, Emergencia o todas. El selector de estado permite contenido, carga/envío, error y vacío/sin ubicación. Movimiento reducido y escala 100/150/200 % sirven para examinar los ejemplos. Login no tiene estado de lista vacía: esa selección conserva el formulario normal.

El Login izquierdo es la captura propia Flutter DEV del Incremento 6, con las limitaciones tipográficas de QA allí documentadas. Inicio, Alertas y Emergencia izquierdos son **reconstrucciones HTML del código**, no capturas Android ni réplicas exactas. La columna propuesta aprovecha las composiciones HTML anteriores y refina componentes, espaciado, jerarquía y estados. No se presenta como implementación existente.

En paletas históricas se conserva la comparación anterior: mismas composiciones HTML en ambos lados, navy anterior `#1B2B48` frente a `#031B3B`. Por eso se parecen mucho: ese modo aísla color, no representa el refinamiento completo ni la aplicación actual.

Las acciones de producto están deshabilitadas. El ojo solo muestra/oculta una contraseña ficticia en el HTML: aún no es un cambio Flutter. Los botones del banco confirman respuesta visual local, sin autenticación, almacenamiento o red. **Google Sign-In permanece pendiente funcionalmente y no aparece como botón operativo.**

## Recomendaciones

- Navy de marca como primario único; Aqua intacto, teal `#006D68` para interacción accesible y selección tonal.
- Manrope, escala accesible y sentence case; radios y spacing actuales. Sombras solo con propósito.
- Login con correo/candado, etiquetas persistentes, foco/error legibles y futura visibilidad de contraseña; cabecera y escena D conservadas.
- Inicio con un vehículo protagonista y datos separados de disponibilidad; Alertas con grupos/filas; Emergencia estable con ubicación antes de diagnóstico y alcance del acuse.
- Material outline inicialmente, Lucide solo referencia sin dependencia; motion finito 120/180/240 ms y emergencia inmediata.

DS1–DS8 y el plan Flutter posterior están en [la propuesta consolidada](DESIGN_SYSTEM_V1_PROPOSAL.md#decisiones-para-aprobación). El Design System no está aprobado. Copy dependiente de frescura, mapas/llamada y Google se resuelve mediante tareas funcionales separadas.

## Reproducibilidad y límites

`python build.py` actualiza página, tokens JS y contraste desde fuentes locales. `node verify.mjs` verifica el navegador instalado sin dependencias nuevas. `login.png`, `inicio.png`, `alertas.png`, `emergencia.png` son capturas propias de la comparativa, no recursos de ejecución de la app. `browser-validation.json` registra resultados. `preserved-files.json` conserva hashes de seis recursos originales de Motion Prototype 01; no se altera la secuencia ni los SVG.

La tabla incluye pares candidatos y pares históricos restringidos, no una aprobación indiscriminada del acento. Ver `contrast.json` y `ACCESSIBILITY.md`. No certifica TalkBack ni rendimiento Android. No se repiten pruebas Flutter o compilación durante esta tarea documental.

Validación de esta entrega: **28 comprobaciones de navegador satisfactorias**, cuatro capturas inspeccionadas, 31 pares de contraste calculados (26 cumplen su objetivo; cinco usos históricos/restringidos no cumplen). Enlaces documentales locales verificados. Se comprobó con Git que no hay cambios en `lib/`, `test/`, dependencias, Motion Prototype 01 ni `composition_v3`. El manifiesto de hashes se actualiza al estado D ya conservado en el historial, posterior a la antigua comparación de paletas; no implica edición del prototipo durante esta tarea.

Para revisar: **SDA apagado, bridge detenido; app/celular e Internet innecesarios.** Firebase real y Emulator no se usan. Sin cambios Flutter, dependencias, commits ni push. Se detiene el trabajo en la revisión del Design System; implementación posterior requiere autorización.
