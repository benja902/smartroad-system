# URBES — Motion Prototype 01

**Actualizado el 15 de octubre de 2026. Prototipo de navegador para revisión; no aprobado para Flutter.** Basado en la dirección isométrica 2.5D, familia, paleta y composición de v2 aprobadas provisionalmente. Sin nueva composition_v3.

[Abrir prototipo](index.html) · [Prueba de giro](turn-contact.png) · [Construcción](full-build.png) · [Nuevo cierre de marca](brand-close.png) · [Entrega](handoff.png) · [Login final](login.png).

## Variantes vehículo–isotipo para comparar

### D — Baliza flotante · comparación con C

Se conserva **C sin cambios visuales** y se añade D al mismo selector. D mantiene T4 oculto, el anclaje original de la U, entrada 720–960 ms, recorrido del auto, impulso base y entrega al Login. No se añade reproductor ni controles.

- **Espera:** de 960 a 2160 ms, una sola elevación y regreso de 2 unidades del lienzo móvil. Dos tramos de smootherstep quíntico de 600 ms; velocidad/aceleración nulas al inicio, en la cima de 1560 ms y al terminar. Reposa 240 ms antes del encuentro. Sin giro ni deformación del símbolo.
- **Profundidad:** elipse navy de radios 10×4 y opacidad máxima 0,11 bajo el isotipo, en el pie proyectado de la escena. Se contrae hasta 9,2×3,7 y opacidad 0,09 al elevarse la U. Orientación −30° sobre el plano vial, sin blur, filtros o luces pulsantes. Aparece con la U y desaparece de 2680 a 2800 ms; no viaja a la cabecera.
- **Encuentro:** sigue el cue geométrico de 2400 ms, cuando el frontal se aproxima a la huella de la baliza. No se cambia el auto para simular una colisión. Desplazamiento máximo de 3 unidades en el sentido proyectado real de avance, envolvente `sin²(πp)` de 280 ms; vuelve al anclaje y enlaza con la salida original a 2680 ms, sin salto.
- **Onda:** expansión única en la base, radios 10→22 y 4→9, opacidad máxima 0,65, durante esos mismos 280 ms. Sin onda ni reacción antes del cue. El pulso interno del SVG oficial no se redibuja ni se anima.
- **Entrega:** desde 2680 ms comparte exactamente la trayectoria de C, salvo la sombra de suelo que termina de desaparecer. Total 4440 ms. Omisión, movimiento reducido y emergencia retiran la decoración inmediatamente; cambiar de recorrido limpia los efectos exclusivos de D.

Las distancias son unidades de diseño del SVG móvil de 390×844, no dp Android ni píxeles físicos. La reacción continúa siendo una aproximación visual por proximidad, no simulación de contacto rígido o estado real de conectividad. Comparar C/D a 1× y 0,25× antes de aprobar. Los SVG de la propuesta estática y las versiones anteriores se conservan.

### C — Impulso refinado · 16 de octubre

Nueva opción adicional del selector, autorizada para revisión. Conserva exactamente el montaje, posición original del isotipo, impulso y entrega de A, con dos cambios: **T4 (`object-tree-3`) no se muestra en C**, y la entrada del isotipo se adelanta a **720–960 ms**, ease-out cúbica de 240 ms. El vehículo comienza a entrar a 600 ms: desfase de 120 ms. El símbolo espera estable hasta la reacción geométrica de 2400 ms; no se adelanta el impulso.

Duración total 4440 ms, sin cambios en trayectoria/velocidad del vehículo ni en el formulario. La exclusión de T4 se limita a C, incluida su entrega final y omisión; volver a A, B o giro aislado restaura el árbol. El recurso original no se elimina ni se modifica. C reutiliza el mismo reloj, renderer, símbolo, curvas y controles. Su composición se basa en la propuesta estática `composition_v3/proposals/encounter-a-2510-no-t4.svg`, con la U en su ubicación original.

Comparar A y C a 1× y 0,25×: la diferencia inicial es presencia temprana del destino y ausencia de T4, no una nueva trayectoria. Se actualiza el storyboard v3 con diez estados específicos de C. La selección final y cualquier implementación Flutter siguen pendientes.

Se añaden **A. Impulso del isotipo** y **B. Activación del isotipo** al selector existente. Ambas son propuestas pendientes de revisión humana; no se elige ganadora ni se autoriza Flutter. Los tres recorridos anteriores siguen disponibles y conservan sus tiempos. No hay nueva página, controles, reproductor, dependencias o Design System.

| Aspecto | A — Impulso | B — Activación |
|---|---|---|
| Encuentro | Anillo turquesa elíptico, una expansión de 280 ms. El símbolo crece como máximo 3,5 % y vuelve a su tamaño. | Conexión turquesa fina de 220 ms entre el frontal proyectado y el pie del isotipo. Símbolo estable, sin rebote. |
| Salida | Arco más amplio por la derecha de la escena, como continuación del impulso. | Arco más contenido, sin expansión ni oscilación. |
| Reunión con URBES | Un único símbolo llega junto al nombre que ya espera debajo de la escena. | Mismo destino y alineación, para comparar el gesto con igualdad de tiempos. |
| Cabecera y Login | Símbolo y nombre viajan como un grupo; se conserva el escalonado del formulario. | Idéntico montaje final. |

**Revisión:** elegir A, reproducir a 1× y después a 0,25×; repetir con B. A velocidad reducida el recorrido dura aproximadamente 17,76 s. Pausar o usar la barra para examinar 2400 ms (encuentro), 2680–3360 ms (salida/reunión), 3540–4090 ms (cabecera/ilustración) y 4090–4410 ms (formulario). No hay autoplay ni selector adicional.

### Sincronización y geometría

Se reutilizan `VehicleMotion.at`, `ease` y `project`. El vehículo conserva el mismo recorrido de 2000 ms, de **600 a 2600 ms** dentro de la secuencia completa. Su frontal se aproxima con el punto local `(44,0,0)` orientado mediante la pose actual. El pie del isotipo está en `(236,13,0)` y su centro en `(236,13,26)`, la zona del antiguo escudo de v2.

Al preparar el montaje se busca el primer instante en que la distancia proyectada frontal–pie es ≤16 unidades de escena: **2400 ms** con la trayectoria actual. Son aproximadamente 9,6 unidades en el lienzo móvil. Se trata de un encuentro por proximidad, no de una colisión física ni una lectura de conectividad. La señal B conecta esos puntos y se recalcula con la pose del vehículo. Si cambia la ruta en el futuro, el instante se deriva de ella; no depende de un callback o temporizador independiente.

Toda la presentación es una función del mismo tiempo de revisión. Saltar hacia atrás/adelante reconstruye el estado sin acumular eventos, partículas o instancias del logo. Una sola referencia al símbolo original se traslada y escala uniformemente; no se rotan, deforman ni recolorean sus trazados. El logo es un gráfico orientado a cámara, como el antiguo escudo, y no un objeto volumétrico sobre la carretera.

### Montaje común de A/B — 4440 ms

| Tiempo | Acción | Curva |
|---|---|---|
| 0–1100 aprox. | Construcción por capas original | Ease-out cúbica y escalonado existentes. |
| 600–2600 | Vehículo, sin cambios | Distancia proyectada + smootherstep quíntica existente. |
| 1550–1850 | Isotipo de 28,8 unidades aparece junto al destino | Opacidad ease-out cúbica; sin giro ni salto de posición. |
| 1900–2200 | URBES aparece bajo la escena | Opacidad ease-out cúbica. |
| 2400–2680 A / 2400–2620 B | Reacción única | Envolvente `sin²(πp)`, inicio/final de amplitud cero. |
| 2680–3360 | Símbolo hasta URBES, de 28,8 a 57,6 unidades | Bézier cúbica de posición, avance smootherstep `6p⁵−15p⁴+10p³`. |
| 3360–3540 | Reposo de la marca reunida | Sin movimiento. |
| 3540–4090 | Marca agrupada hasta cabecera; escena hasta ilustración superior | Smoothstep cúbica existente; trayectoria por margen izquierdo. Escala uniforme del grupo 1→0,625; símbolo final de 36 unidades. |
| 4090–4330 | Título del Login | Ease-out cúbica, desplazamiento existente de 6 px. |
| 4130–4370 | Campos | Mismo tratamiento, retraso de 40 ms. |
| 4170–4410 | Botón | Mismo tratamiento, retraso de 80 ms. |
| 4410–4440 | Estado final | Estático. |

En coordenadas móviles, el arco A usa controles `(365,440)` / `(131,510)`; B usa `(310,490)` / `(131,520)`. Ambos parten de la proyección del isotipo y terminan en `(131,633)`, acercándose desde arriba para no atravesar el texto. El avance quíntico anula velocidad y aceleración al partir/llegar. Después del docking se mueve el padre `brand-lockup`: nombre y símbolo conservan su separación y opacidad, sin fundidos de sustitución. Su centro X sigue `42+89(1−d)³`, manteniendo margen izquierdo durante la entrega. La ilustración mantiene su escala y desplazamiento originales; únicamente se pospone la entrega para permitir la interacción.

Movimiento reducido y omisión llevan directamente al mismo Login estático, sin señal residual. Emergencia retira toda la escena inmediatamente y prevalece sobre reproducción/omisión. Estas son simulaciones conceptuales locales, sin autenticación, comunicaciones ni acciones reales.

**Límites específicos:** A/B añaden 640 ms al montaje original de 3800 ms; no son una propuesta aprobada de espera Android. El punto frontal es una aproximación visual y el umbral de proximidad necesita valoración humana. La señal no acredita estado del SDA, ubicación ni conectividad. La lectura a velocidad normal y lenta sigue pendiente de tu selección; continuidad numérica y reproducción en navegador no garantizan percepción premium, TalkBack o rendimiento Android.

## Ajuste aprobado: arranque y nueva identidad

El 15 de octubre se autorizó retirar la carretera vertical inicial e incorporar el SVG proporcionado. El montaje comienza directamente con el suelo isométrico tenue en su posición definitiva, sin otra intro previa. La secuencia se acorta 200 ms; el recorrido del vehículo conserva exactamente su duración de 2000 ms, geometría y perfil de velocidad.

`logo.svg` es una copia idéntica del archivo suministrado (hash SHA-256 comprobado). Conserva sus tres trazados, transformaciones y colores `#031B3B` / `#14E0D3`. Se acompaña de URBES en Manrope. Se retiraron el lettering provisional y el escudo flotante de la escena, sin cambiar la paleta del entorno ni el Design System global.

En el recorrido original **Secuencia completa** hay una sola instancia visible del símbolo. Aparece bajo la escena y se reduce de 96 a 36 unidades para alcanzar la cabecera; sigue una trayectoria por el margen vacío izquierdo para no cruzar por delante de los objetos. El texto del cierre se desvanece y vuelve a aparecer en la cabecera, sin deformar letras. El pulso del archivo permanece estático: no late, no se traza ni cambia de color. La marca llega antes de la entrada del formulario. A/B conservan este recorrido como comparación y exploran el encuentro descrito arriba.

El arranque nativo Android no se modifica ni se simula como una pantalla previa. Su adaptación futura necesita autorización Flutter específica. v1 y v2 se conservan como antecedentes históricos.

## Abrir y revisar

Abrir `index.html` directamente en Chrome o Edge. No requiere servidor, paquetes, Internet ni backend. Se carga Manrope desde el recurso local existente. No se reproduce automáticamente.

1. Dejar seleccionado **Solo vehículo** y pulsar **Reproducir**. Observar la curva a 1× y luego a 0,25×. El lienzo amplio permite inspeccionar carrocería, cristales, ruedas y oclusiones.
2. Usar **Pausar**, el deslizador y **Reiniciar**. Reproducir de nuevo después del final reinicia la secuencia. Cambiar velocidad no reinicia el tiempo.
3. Elegir **Secuencia completa**, reproducir y revisar orden de capas, cierre de marca y entrada del formulario.
4. Elegir **Splash → Login** para observar solo los últimos 900 ms del montaje original, sin repetir construcción/recorrido. Elegir **A. Impulso** o **B. Activación** para comparar el encuentro con el isotipo.
5. Durante la reproducción, probar **Omitir introducción**, **Omitir animaciones decorativas** y **Simular prioridad de emergencia**. El estado crítico prevalece hasta salir de esa simulación.

El movimiento reducido del sistema se respeta además del control manual. Desmarcar el control no puede anular una preferencia de sistema activa. Al desactivar reducción no se reinicia nada automáticamente. Ocultar la página durante reproducción termina la intro; volver no la reproduce.

El formulario contiene únicamente valores ficticios de solo lectura. El botón no envía datos, no autentica ni cambia rutas. No introducir credenciales reales. El ojo es decorativo; no implementa una función nueva.

## Primera puerta: giro del vehículo

Se construyó y revisó la prueba aislada **antes** de implementar el montaje completo.

Las tres poses v2 no se usan como sprites ni se interpolan como dibujos planos. `prepare.py` extrae 42 superficies/detalles de las coordenadas del vehículo del generador v2. Se rotan sus coordenadas en el plano del suelo y se reproyectan con cámara ortográfica fija en cada fotograma. Se conservan dimensiones, pivote central y altura; cambian las caras visibles conforme cambia el rumbo.

La ruta reutiliza la carretera v2: recta de entrada, curva cúbica y recta de salida. El tramo recorrido empieza en (64,205), sigue la curva entre (135,205) y (235,113), y termina en (235,70), antes del signo. La tangente se calcula en coordenadas del mundo; no se confunde el ángulo proyectado de pantalla con el rumbo espacial del vehículo.

Una tabla de longitud proyectada evita aceleraciones causadas únicamente por muestrear la Bézier en parámetros equidistantes. La velocidad de recorrido usa una función quintica continua con aceleración y frenado suaves. Cámara y escala no cambian durante el modo vehículo. La silueta proyectada varía naturalmente al girar, sin aplicar escalados para fingir vistas intermedias.

**Evidencia del primer control:** 1.201 muestras matemáticas, rumbo monotónico de 0° a −90°, sin coordenadas no finitas, máximo paso angular de aproximadamente 0,276° entre muestras separadas por 1/1200 del recorrido temporal. Se inspeccionaron 12 renders intermedios, particularmente alrededor del cambio de vista lateral. [Resultado geométrico](geometry-validation.json).

Se detectó que el apilado del dibujo estático v2 ponía el auto por delante del pabellón. Se particionó el primer plano dentro del prototipo para que pabellón, banco y árboles delanteros lo ocluyan cuando corresponde. También se corrigió la orientación de normales para descartar caras posteriores y mantener las caras visibles durante el giro. No se editaron los SVG ni el generador de v2.

La continuidad geométrica y las vistas intermedias fueron suficientes para continuar con el montaje experimental. **No constituyen una aprobación humana de fluidez ni una medición de FPS.** La comprobación automática posterior confirmó ejecución real de `requestAnimationFrame` y finalización de la secuencia completa sin adelantar el tiempo manualmente; el juicio visual de la reproducción continua a 1×/0,25× queda para esta revisión del usuario.

## Tiempos y curvas candidatos

| Elemento | Ventana en montaje completo | Curva / tratamiento |
|---|---|---|
| Suelo | Desde el primer fotograma hasta 320 ms | Estado inicial tenue (opacidad aproximada 0,166), `easeOutCubic`; escala sutil hasta 1. |
| Carretera y señalización | 70–450 ms | `easeOutCubic`; escala 0,992→1. |
| Edificio | 230–630 ms | `easeOutCubic`; 8 unidades; escala 0,985→1. |
| Pabellón | 350–710 ms | `easeOutCubic`; 6 unidades; escala 0,985→1. |
| Vegetación | Inicios 380, 435, 490, 545, 600 y 655 ms; 300 ms por copa | `easeOutCubic`; 4 unidades; escala 0,98→1. |
| Banco / farolas | 580–840 / 640–900 ms | `easeOutCubic`; 3 unidades. |
| Vehículo | 600–2600 ms; aparición 600–780 ms | Recorrido `6p^5-15p^4+10p^3`; sin cambio de trayectoria/duración. |
| Nuevo logo y URBES | 2300–2600 ms | Aparición `easeOutCubic`; símbolo sin latido. |
| Reposo de cierre | 2600–2900 ms | Escena y marca estables. |
| Entrega de escena | 2900–3450 ms | `smoothstep`, `3p^2-2p^3`; y=270→71, x=14 y escala=0,60 constantes. |
| Logo hacia cabecera | 2900–3450 ms | Trayectoria curva por margen izquierdo; reducción temprana y suave 96→36. Nombre sale durante el primer 30 % y reaparece durante el último 15 % de la entrega. |
| Título | 3450–3690 ms | `easeOutCubic`; 6 px hacia posición final. |
| Campos | 3490–3730 ms | Misma curva y desplazamiento, después del título. |
| Botón | 3530–3770 ms | Misma curva y desplazamiento, después de campos. |

Las unidades de la escena corresponden al mundo SVG; se proyectan y escalan con el grupo, no equivalen directamente a dp de Android. Las entradas HTML usan píxeles CSS.

**Duraciones de revisión:** vehículo 2000 ms; montaje completo 3800 ms; entrega aislada 900 ms. A 0,5× el tiempo de pared es aproximadamente el doble; a 0,25×, cuatro veces mayor. La línea temporal usa timestamps de `requestAnimationFrame`, no un contador de fotogramas. Un avance individual se limita a 40 ms: una pausa larga puede prolongar la duración real en lugar de saltarse la escena. [API del navegador](https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame).

Los 3800 ms son exploratorios y **no sustituyen los 1900 ms de Brand Intro 01 ni autorizan una espera funcional en Flutter**. No hay solicitud de autenticación esperando a que termine el montaje. La futura integración deberá conservar inicialización y redirección existentes sin sujetarlas a esta línea temporal.

## Continuidad e interrupciones

Existe una sola instancia del mundo ilustrado durante Splash y Login. La entrega modifica la transformación del grupo, sin duplicarlo ni reiniciar el auto. El formulario empieza cuando termina esa entrega, y campos/acción no se pueden enfocar mientras están invisibles. No existe una entrada del formulario que se consuma bajo un overlay.

- **Omitir:** cancela el frame pendiente y presenta Login final estático.
- **Movimiento reducido:** mismo resultado, también al activarse durante la reproducción. La preferencia se consulta mediante `prefers-reduced-motion`. [Referencia](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion).
- **Segundo plano:** el evento `visibilitychange` finaliza una reproducción activa; no se reanuda al volver.
- **Prioridad crítica:** se cancela la reproducción y se ocultan escena, marca y formulario inmediatamente. Reproducir/omitir/reducir movimiento no retiran el estado crítico. Solo su salida explícita devuelve al destino estático.
- **Sesión abierta:** no existe una sesión en este prototipo. No se simula autenticación para forzar Login; en Flutter el destino tendrá que seguir siendo el resuelto por el router. El prototipo únicamente estudia el destino Login.

La simulación crítica no es una alerta real, no dispara SOS y no prueba el router, EventProvider o Firebase. Conserva conceptualmente la prioridad exigida; las garantías reales vigentes siguen en el código y pruebas Flutter intactos.

## Recursos y alcance

Reutilizados: `composition_v2/scene-isometric.svg`, coordenadas del vehículo de `composition_v2/illustrate.py` y Manrope local. Identidad actual: `logo.svg` suministrado por el usuario y autorizado para este HTML. Recibir el archivo no establece una licencia externa ni exclusividad registral. [Licencias de los antecedentes](../composition_v2/LICENSES.md).

Adaptaciones confinadas aquí: `assets.js` contiene una única escena y el despiece; `vehicle.js` realiza proyección/visibilidad; `prototype.js` coordina timeline/controles; HTML/CSS presentan el estudio y formulario ficticio. No se generó un atlas de cientos de poses. No se descargaron nuevos recursos.

No hay Rive, Lottie, WebGL, librerías de animación ni nuevas dependencias. Las superficies se reproyectan a SVG con JavaScript nativo. Esto demuestra una vía de prototipado; no selecciona aún la arquitectura final Flutter.

## Validación

- [109/109 comprobaciones de navegador](browser-validation.json), ejecutadas en Chrome headless con perfil efímero independiente, apertura directa `file://` y sin servidor. Incluyen las 26 anteriores, las siete opciones del selector, 18 comprobaciones por variante A/B/C/D, cuatro verificaciones específicas de C y seis de D (flotación, estabilización, reacción, limpieza, restauración y continuidad): reproducción completa real a 1×/0,25×, cue geométrico, conservación del vehículo, instancia única, continuidad de matrices en límites, docking, separación respecto al texto, margen izquierdo, formulario, controles, omisión, emergencia y reducción manual/sistema. No hay una prueba perceptual automática del movimiento.
- Capturas de las reacciones: [A. Impulso](impulse.png) , [B. Activación](activation.png) , [C. Impulso refinado](refined.png) y [D. Baliza flotante](beacon.png). El SVG original, `assets.js`, `vehicle.js` y `styles.css` se conservan; los scripts y tiempos del recorrido anterior mantienen sus controles y resultados. La comparación de geometría cubre cinco posiciones compartidas, no cada fotograma.
- `brand_system_proposal/preserved-files.json` conserva los hashes del checkpoint anterior. Esta iteración autorizada cambia `index.html` y `prototype.js`, por lo que la comprobación de esos dos hashes en el verificador de aquella propuesta deja de ser aplicable al prototipo actualizado. No se regeneró esa instantánea ni se modificó su comparativa; logo, escena, vehículo y CSS conservan sus recursos originales.
- Validación de continuidad en 1.201 muestras y sintaxis JavaScript sin errores. El primer test de ancho detectó y motivó corregir la cuadrícula de controles. Una espera inicial de 180 ms en el test del loop fue demasiado corta en una ejecución; se sustituyó por espera acotada a observar tres callbacks reales, sin alterar el motor para satisfacer el test.
- Capturas inspeccionadas: giro aislado, construcción, entrega y Login. No se afirma haber observado todos los fotogramas de una reproducción continua mediante capturas.
- No se ejecutaron pruebas Flutter, builds, Firebase Emulator, servicios reales ni hardware físico. Sin cambios a v1/v2, Flutter, Design System, autenticación, rutas, firmware o dependencias. Sin commit ni push.

Comandos locales opcionales para reproducir verificación (Node/Chrome/Python ya instalados):

```powershell
node docs/ui_ux/premium_phase1/motion_prototype_01/verify_geometry.mjs
node docs/ui_ux/premium_phase1/motion_prototype_01/verify_browser.mjs
```

`prepare.py` regenera el único payload desde v2 sin escribir allí; no hace falta ejecutarlo para abrir el prototipo. `render_gate.py` exporta la hoja de giro. Los verificadores solo eliminan sus perfiles temporales recién creados tras comprobar su ubicación.

## Limitaciones y alternativas

1. El vehículo es una representación vectorial de volumen sencillo; no tiene suspensión, giro independiente de ruedas ni detalle mecánico animado. Su sombra es una huella elíptica con luz fija, distinta de la sombra rectangular de la pose v2.
2. La selección de caras y su orden por profundidad media cubren esta curva y esta cámara. No equivalen a un renderizador 3D general con z-buffer; otras rutas, obstáculos o un giro completo requerirán nueva revisión de oclusiones. La partición del entorno es específica de este recorrido.
3. La curva cambia de curvatura al unirse a rectas, aunque posición y tangente son continuas. Si se percibe un inicio/final de giro demasiado marcado, se podrá suavizar la geometría o el perfil de velocidad antes de integrar.
4. No se simula tiempo de carga Android, señal de primer fotograma rasterizado ni máscara del splash Android 12+. No hay carretera vertical previa ni morph carretera→escudo. La adaptación del arranque Android queda fuera de este prototipo.
5. Login es una maqueta de lectura. Teclado, autofill, errores de Auth, escalado máximo y TalkBack reales están pendientes; la prueba a 320 px no certifica accesibilidad móvil completa.
6. Chrome headless verifica funcionamiento y renders; no mide ni garantiza percepción de fluidez en el monitor del usuario, FPS estables, consumo, memoria total o rendimiento Android. No se atribuyen técnicas a Beeway/Parcel/Skyward.

Si el giro no convence en revisión humana, mantener este montaje experimental y resolver primero el vehículo: **A)** refinar superficies y geometría en este modelo vectorial continuo; **B)** ilustrar un conjunto pequeño de vistas de rumbo con transiciones controladas, aceptando más autoría/archivos; **C)** reconsiderar cenital si prima sencillez del giro. Introducir Rive/Lottie no corrige por sí solo una perspectiva incorrecta. Ninguna alternativa está seleccionada ni autoriza pasar a Flutter.

## Próxima decisión

Aprobar o señalar ajustes del giro a 1×/0,25×, escalonado de capas, reposo de marca y entrega/formulario. **Se espera aprobación del prototipo animado antes de cualquier trabajo Flutter.** La aprobación artística provisional permanece acotada y no cierra decisiones globales ni despliegues.

Para revisar: **SDA apagado; bridge detenido; app Flutter/celular innecesarios; Internet innecesario**. Firebase real y Emulator no se utilizan; no hace falta apagar el proyecto Firebase.
