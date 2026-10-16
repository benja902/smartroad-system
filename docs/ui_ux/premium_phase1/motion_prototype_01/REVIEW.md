# URBES — Motion Prototype 01

**Actualizado el 15 de octubre de 2026. Prototipo de navegador para revisión; no aprobado para Flutter.** Basado en la dirección isométrica 2.5D, familia, paleta y composición de v2 aprobadas provisionalmente. Sin nueva composition_v3.

[Abrir prototipo](index.html) · [Prueba de giro](turn-contact.png) · [Construcción](full-build.png) · [Nuevo cierre de marca](brand-close.png) · [Entrega](handoff.png) · [Login final](login.png).

## Ajuste aprobado: arranque y nueva identidad

El 15 de octubre se autorizó retirar la carretera vertical inicial e incorporar el SVG proporcionado. El montaje comienza directamente con el suelo isométrico tenue en su posición definitiva, sin otra intro previa. La secuencia se acorta 200 ms; el recorrido del vehículo conserva exactamente su duración de 2000 ms, geometría y perfil de velocidad.

`logo.svg` es una copia idéntica del archivo suministrado (hash SHA-256 comprobado). Conserva sus tres trazados, transformaciones y colores `#031B3B` / `#14E0D3`. Se acompaña de URBES en Manrope. Se retiraron el lettering provisional y el escudo flotante de la escena, sin cambiar la paleta del entorno ni el Design System global.

Hay una sola instancia visible del símbolo. Aparece bajo la escena y se reduce de 96 a 36 unidades para alcanzar la cabecera; sigue una trayectoria por el margen vacío izquierdo para no cruzar por delante de los objetos. El texto del cierre se desvanece y vuelve a aparecer en la cabecera, sin deformar letras. El pulso del archivo permanece estático: no late, no se traza ni cambia de color. La marca llega antes de la entrada del formulario.

El arranque nativo Android no se modifica ni se simula como una pantalla previa. Su adaptación futura necesita autorización Flutter específica. v1 y v2 se conservan como antecedentes históricos.

## Abrir y revisar

Abrir `index.html` directamente en Chrome o Edge. No requiere servidor, paquetes, Internet ni backend. Se carga Manrope desde el recurso local existente. No se reproduce automáticamente.

1. Dejar seleccionado **Solo vehículo** y pulsar **Reproducir**. Observar la curva a 1× y luego a 0,25×. El lienzo amplio permite inspeccionar carrocería, cristales, ruedas y oclusiones.
2. Usar **Pausar**, el deslizador y **Reiniciar**. Reproducir de nuevo después del final reinicia la secuencia. Cambiar velocidad no reinicia el tiempo.
3. Elegir **Secuencia completa**, reproducir y revisar orden de capas, cierre de marca y entrada del formulario.
4. Elegir **Splash → Login** para observar solo los últimos 900 ms del montaje, sin repetir construcción/recorrido.
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

- [26/26 comprobaciones de navegador](browser-validation.json), ejecutadas en Chrome headless con perfil efímero independiente, apertura directa `file://` y sin servidor. Incluyen ejecución real del loop, pausa, reinicio, velocidad seleccionable, secuencia completa hasta final sin scrubbing, entrega, foco del formulario, omisión, prioridad crítica, reducción manual/sistema, simulación de segundo plano, repetición sin acumular geometría y ancho de revisión de 320 px.
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
