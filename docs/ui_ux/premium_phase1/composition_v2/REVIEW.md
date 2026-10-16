# URBES Premium Redesign — composition_v2

**14 de octubre de 2026. Propuesta artística pendiente de aprobación.** Continuación de la auditoría aceptada y de `composition_v1`; sin implementación Flutter ni animación definitiva.

[Revisión completa](index.html) · [Comparativa v1/v2](comparison.png) · [Dos perspectivas](directions.png) · [Storyboard](storyboard.png) · [Poses del vehículo](heading.png) · [Fuentes/licencias/costes](LICENSES.md).

## Recomendación

**Isométrica 2.5D, con una familia propia y paleta contenida.** La v1 resolvió continuidad y economía de recursos, pero sus parcelas abstractas, trazos tenues y vehículo pequeño aportaban poca riqueza visual estando detenidos. La v2 prioriza reconocimiento: un auto con volumen y cristales, una fachada con ventanas, tejado de tejas, parque, banco, farolas y un pequeño pabellón con cubierta técnica.

La inspiración Beeway se toma de la construcción por capas y el equilibrio entre objetos; Parcel aporta recorrido y cambio de rumbo; Skyward, persistencia del motivo entre pantallas. No se copian personajes, marcas ni escenas externas. Los videos no se volvieron a inspeccionar en esta iteración: siguen vigentes los límites del muestreo documentado en v1.

La recomendación cambia respecto a la exploración cenital anterior porque ahora la prioridad explícita es calidad estática y profundidad. La sencillez del movimiento sigue siendo una ventaja real de la cenital, pero no determina por sí sola la dirección artística.

## Comparación de perspectivas

| Criterio | Isométrica 2.5D | Cenital ilustrada |
|---|---|---|
| Reconocimiento de objetos | Fachadas, ruedas, carrocería y mobiliario visibles; más profundidad. | Buen reconocimiento del vehículo/camino; arquitectura se lee principalmente como tejados. |
| Composición por capas | Suelo, objetos bajos/altos, vehículo y marca generan planos claros. | Capas mediante tamaño, luz, oclusión y sombras; menor diferencia entre alturas. |
| Recorrido tipo Parcel | Viable, pero rumbo altera la vista del auto. Necesita poses/volumen coherentes. | Una vista cenital puede orientarse con la tangente; menor complejidad. |
| Coste de arte | Mayor: despiece, caras visibles, oclusión y revisión de giros. | Menor: pivote y rotación estables, menos caras. |
| Escalado a Login | Escena compacta conserva carácter; evitar detalle demasiado fino. | Muy legible como ruta, aunque puede parecer un mapa. |
| Riesgo | Rotar un bitmap/SVG plano de tres cuartos produce una perspectiva incorrecta. | Confundir la ilustración con seguimiento/ubicación reales; simplificar demasiado otra vez. |

Se dibujaron ambas vistas del mismo mundo y paleta. La lámina cenital es una **alternativa de dirección**, no un segundo pack de recursos ni otro Login terminado. Las tres poses isométricas son anclajes de rumbo; todavía no prueban interpolación suave.

## Familia gráfica y calidad estática

La composición principal utiliza proyección axonométrica fija: los ejes del suelo están a ±30° respecto a horizontal y la vertical conserva altura. Todos los objetos pertenecen al mismo mundo; no se pega un coche cenital a edificios isométricos. El emblema URBES es una superposición gráfica de marca, con lectura frontal intencionada, no un objeto físico cuya perspectiva se deba confundir con la del edificio.

La profundidad procede de caras de distinto tono, sombras vectoriales sin blur, ventanas rehundidas, cubiertas, voladizos y solapamientos. Las copas tienen contornos orgánicos, varias masas de follaje y luz superior. El auto añade cuatro ruedas, cristales, techo, capó, espejos, uniones de carrocería, luces y parachoques. No se limita a recolorear los SVG v1.

Paleta ilustrativa local: navy `#1B2B48`, teal `#347E84`, luz teal `#79AAA6`, terracota `#D38B70`, fondo `#F8F9FA`; neutros arquitectónicos y tonos derivados completan luz/sombra. La familia cromática es reducida, aunque contiene variaciones tonales, no solo cinco rellenos. Ningún color decorativo afirma «conectado», «operativo» o «sin incidentes». Estos valores no cambian `AppColors`, `AppTheme` ni decisiones globales D1–D3.

No se añadieron personajes: no hacen falta para expresar la relación vehículo/ruta/protección en esta composición y complicarían escala, perspectiva y narrativa. Si se quieren después, deberán diseñarse dentro de esta familia, no tomarse de una colección incompatible.

## Splash v2

[SVG Splash](splash-v2.svg) · [Escena editable](scene-isometric.svg).

La escena se centra sobre una base vial recortada: edificio al fondo, tramo de entrada con cruce peatonal, curva amplia y parque en primer plano. El coche oscuro contrasta con el asfalto gris azulado; el tejado terracota aporta un contrapunto cálido. El escudo provisional se asocia al extremo del recorrido. El nombre monolineal de Brand Intro 01 cierra debajo, sin una nueva promesa de servicio o un claim inventado.

No es un mapa geográfico ni una representación del SDA real. El pabellón no implica una estación de rescate, backend desplegado, capacidad de conducción autónoma o infraestructura existente. Los objetos aportan contexto vial abstracto.

La escala de la escena es 0,60 respecto al mundo vectorial de referencia y el anclaje de presentación es (14,270) en un lienzo de 390 × 844. La composición se evalúa como una imagen estática; se podrá ajustar escala/densidad antes de motion. La primera lámina de storyboard mantiene el recurso nativo vigente. La unión hacia el mundo isométrico queda pendiente de diseñar en movimiento; no se promete que el vector nativo se transforme geométricamente en toda la escena.

## Login v2

[SVG Login](login-v2.svg).

Se reutiliza exactamente el mundo isométrico, el vehículo y el signo URBES; la escena pasa al anclaje (14,71), conservando escala 0,60. El auto termina orientado en el tramo de salida. Marca pequeña en cabecera, título «Bienvenido.», copy y orden correo→contraseña→acción del prototipo anterior. Manrope y radios/altura de controles conservan la base existente. No se añaden acceso social, registro, recuperación ni acciones nuevas.

Los campos son **dibujos de revisión**, no un formulario funcional. Una futura adaptación conservará controladores, validadores, errores, autofill, submit, estado de envío y router. El ojo de contraseña procede de la propuesta HTML anterior; todavía no existe en Flutter y su incorporación requiere autorización UI específica.

La escena queda detenida tras la entrega. Al abrir teclado se propone reducir o retirar la cabecera decorativa, permitir scroll y mantener campos/CTA alcanzables. Con error o carga se actualiza la zona funcional sin reiniciar ilustración ni imponer una espera. Texto 200 % y TalkBack requieren una futura comprobación Flutter: escalar un SVG no equivale a reflow accesible.

## Storyboard actualizado

| Paso | Imagen | Intención | Garantía / pendiente |
|---|---|---|---|
| 1 | Carretera nativa vigente | Mantener continuidad inicial Android DEV. | Esperar el primer fotograma rasterizado como hoy; no rediseñar recursos Android aquí. |
| 2 | Suelo y carretera | Establecer perspectiva, recorrido y señalización. | Entrada de la escena por validar; sin morph complejo inventado. |
| 3 | Arquitectura y entorno | Revelado de edificio, pabellón, copas y mobiliario en capas. | Solapamientos breves; evitar una espera separada por objeto. |
| 4 | Auto, signo y nombre | Recorrido orientado y cierre de marca legible. | Poses adicionales en hoja de rumbo; aún sin tiempos/curvas definitivos. |
| 5 | Entrega a cabecera | El mismo grupo sube de y=270 a y=71; el coche concluye su curva. | Una sola escena; wordmark grande se retira y aparece la marca de cabecera. |
| 6 | Login visible | Título y formulario aparecen cuando quedan descubiertos. | Acciones disponibles, sin consumir entrada detrás del overlay. |

El orden por capas no obliga a una secuencia larga. Los 1900 ms de Brand Intro son referencia de comparación; no se aprueba una duración nueva ni se añade espera de autenticación. El comportamiento real puede prolongarse por arranque; estas láminas no lo corrigen ni lo miden.

Con sesión abierta se entrega al destino ya resuelto por el router; no se fuerza Login. Omitir por toque, segundo plano o movimiento reducido termina la escena. Si llega un incidente crítico, toda ilustración/entrega debe retirarse inmediatamente, preservando el flujo existente. El prototipo artístico no modifica estas garantías ni afirma haberlas probado de nuevo.

## Inventario de recursos

| Recurso | Existe / creado en v2 | Trabajo posterior | Candidato externo, sin aprobación |
|---|---|---|---|
| Escudo, nodos, wordmark | Heredados de Brand Intro 01. | Aprobar identidad y normalizar geometría compartida. | No sustituir por stock. |
| Manrope, campos, botón, tokens | Existentes; usados como referencia de presentación. | Reutilizar componentes Flutter tras autorización. | Ninguno necesario. |
| Carretera, bordillos, cruce | Dibujados en v2, capa independiente. | Aprobar trayectoria y dibujar transición nativo→escena. | DrawKit como referencia; no se descargó pack. |
| Auto isométrico | Dibujado en v2; tres poses de revisión. | Refinar curvas, orden de caras/oclusiones y vistas durante giros. | Amico u Ouch podrían evaluarse como familia alternativa, no insertarse aisladamente. |
| Edificio, pabellón, banco, árboles, farolas | Dibujados como objetos separados en grupos SVG. | Ajustar detalle a tamaño real; preparar despiece final aprobado. | Isotopia/Travel & Transport son candidatos de pago excluidos de esta adquisición. |
| Cabecera Login | Reutiliza la escena v2. | Variante compacta para teclado/texto grande y estados reales. | No hace falta una ilustración distinta. |
| Recursos de motion | No implementados. | Storyboard→prueba continua, curvas/tiempos y medición en etapa autorizada. | Rive/Lottie no seleccionados. |

Los SVG contienen grupos `layer-ground`, `layer-road`, `layer-architecture`, `layer-landscape`, `layer-vehicle`, `layer-brand-sign`; dentro del entorno se identifican edificio, pabellón, banco, árboles y farolas. El despiece es editable y suficiente para revisión; no se certifica como rig final de animación. El generador Python usa solo biblioteca estándar y no importa código de la app.

## Fuentes y costes

[LICENSES.md](LICENSES.md) recoge los seis enlaces solicitados, condiciones, precios verificados y límites de inspección. Se descargaron solo tres pequeñas previews públicas para comparación interna, ninguna colección ni vector de terceros. La escena principal es original y no depende de adquirirlas. Las previews no se incorporan a las páginas visuales ni a Flutter.

## Validación y límites

Se generaron 11 SVG y 5 páginas HTML offline, sin scripts, formularios activos, solicitudes de red o almacenamiento. Se renderizaron con Chrome instalado y se examinaron visualmente la comparativa, las dos perspectivas, el storyboard y las poses. La revisión tipográfica de referencia es el HTML con Manrope local; al abrir un SVG suelto puede usarse una fuente de sustitución.

La comprobación estructural verificó XML de los 11 SVG, identificadores únicos y enlaces/anclas de las 5 páginas, además de los seis grupos de capas de la escena maestra. Evidencias: [estructura](structure-validation.json) y [exportaciones](render-validation.json). El renderizador creó perfiles efímeros bajo el directorio temporal del sistema y los retiró; no crea perfiles Chrome dentro de v1/v2. El render local sin GPU no mide el rendimiento Android.

No se instalaron dependencias, adquirieron assets, cambiaron Flutter/Design System/navegación/Firebase ni ejecutaron tests Flutter, builds o hardware. La calidad de movimiento, contraste contextual completo, accesibilidad móvil y coste UI/raster siguen pendientes de una fase autorizada. Una captura de escritorio no acredita fluidez Android.

Se preserva `composition_v1` y el trabajo local ajeno. Sin commit ni push. Las futuras variantes experimentales deberán seguir aisladas en DEV; aprobar arte no autoriza modificar el Login compartido ni la app principal.

## Puerta de revisión

Revisar y aprobar/ajustar: perspectiva isométrica frente a cenital, familia propia, paleta ilustrativa, densidad de entorno, proporción del vehículo y cabecera Login. Después se decidirán recursos finales y se autorizará una prueba de movimiento. La elección todavía no aprueba D1–D3 globales ni la implementación Flutter.

Para revisar los archivos: **SDA apagado, bridge detenido, app/celular innecesarios, Internet innecesario**. Firebase real y Emulator no se utilizan; no hace falta apagar el proyecto Firebase.
