# Fase UI/UX 1 — borrador de especificación visual y de experiencia

**Estado:** propuesta documental pendiente de aprobación. **Alcance:** aplicación Android Flutter del MVP de un vehículo y un SDA. Este documento no declara pantallas implementadas ni autoriza cambios de código, Firebase, firmware, navegación o políticas funcionales.

## Autoridad y límites

- Para el comportamiento implementado prevalecen código y pruebas; para el orden funcional, [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md); para el siguiente bloque de incidentes, [`PHASE2_INCIDENT_SPEC.md`](PHASE2_INCIDENT_SPEC.md). [`AGENTS.md`](../AGENTS.md) rige las acciones del agente.
- [`design_reference/INDEX.md`](design_reference/INDEX.md) clasifica los diseños Stitch como referencias históricas de apariencia. Su cuenta regresiva y sus controles de cancelación/confirmación en la app no son parte del flujo vigente. El texto y el YAML de [`design_reference/DESIGN_SYSTEM.md`](design_reference/DESIGN_SYSTEM.md) contienen colores distintos: el código actual usa los colores semánticos del texto. Esta propuesta no resuelve esa discrepancia por sí sola.
- La propuesta se inspira metodológicamente en jerarquía, espaciado, contraste, contenido e interacción descritos por [UXPeak](https://www.uxpeak.com/), y en los fundamentos de [Material Design 3](https://m3.material.io/foundations/). Los criterios técnicos se apoyan en [temas](https://docs.flutter.dev/cookbook/design/themes), [accesibilidad](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling) y [rendimiento](https://docs.flutter.dev/perf/best-practices) de Flutter. Ninguna de esas referencias sustituye los contratos de SmartRoad.
- El prototipo es experimental: la interfaz no prometerá entrega, atención o respuesta de emergencias que el sistema no pueda confirmar. No se exponen a contactos datos técnicos que no les correspondan. No se amplía el alcance a varios vehículos o SDA.

## 1. Dirección de identidad visual

La intención útil de «Silent Guardian» es transmitir calma durante el monitoreo y claridad inmediata ante una emergencia. La evolución premium debe surgir de precisión tipográfica, espacios consistentes, datos honestos, contraste, respuesta táctil y movimiento medido. Una interfaz cargada de brillos, sombras o animaciones permanentes dañaría esas prioridades.

| Alternativa | Caracterización | Ventaja | Coste o riesgo | Propuesta |
| --- | --- | --- | --- | --- |
| **A. Silent Guardian refinado** | Navy sobrio, superficies claras, Manrope y color intenso reservado a estados; menos tarjetas y elevación más contenida. | Aprovecha código y reconocimiento visual actuales; transición incremental. | Requiere corregir contrastes y la discrepancia entre las dos paletas documentadas. | **Recomendada** para el MVP. |
| **B. Precisión técnica** | Neutros más fríos, divisores finos y estructura más compacta, con énfasis en datos verificables. | Diferencia con claridad estado del SDA, tiempos y calidad de ubicación. | Puede sentirse demasiado instrumental para un usuario en estrés; exige más revisión de legibilidad. | Alternativa si se prefiere una identidad más técnica. |
| **C. Serenidad cálida** | Neutros menos fríos y menor presencia del navy, manteniendo colores semánticos de incidentes. | Tono más humano para familiares y contactos. | Cambia más la identidad visual y exige revisar todas las superficies y pares de contraste. | Solo con aprobación explícita de dirección de marca. |

**Decisión D1 pendiente:** elegir A, B o C. La elección decide la dirección visual, no autoriza aún reemplazar los valores de `AppColors`, la tipografía ni los componentes. **Recomendación:** A, preservando los colores semánticos reconocibles mientras se verifican sus aplicaciones y contrastes. No adoptar automáticamente la paleta YAML histórica ni un color nuevo por estética.

## 2. Design System propuesto

### Roles, no colores sueltos

| Rol | Base actual o criterio | Uso y restricción |
| --- | --- | --- |
| Marca / acción primaria | `#1B2B48` navy actual, provisional bajo D1 | Navegación, títulos prioritarios y acción primaria ordinaria. No representa conectividad. |
| Fondo / superficie | `#F8F9FA` / `#FFFFFF` actuales, provisionales | Separación de planos por tono y espacio; reservar sombra para elementos que realmente la necesiten. |
| Texto principal / secundario | `#1B1B1E` / `#44474D` actuales | El secundario conserva contraste suficiente; `outline` no sustituye texto legible por defecto. |
| Estado operativo confirmado | Verde actual `#2ECC71` como acento | Icono, borde o fondo suave acompañado de texto. Nunca inferir «operativo» solo por falta de datos. |
| Atención / moderado | Ámbar actual `#F39C12` como acento | Distinguir de crítico mediante etiqueta, icono y jerarquía. Elegir un par texto/fondo accesible, no blanco sobre ámbar por defecto. |
| Crítico | Coral actual `#E74C3C` como acento | Reservado a emergencia activa o acción crítica correspondiente; texto y fondo requieren par accesible. |
| Desconocido / sin datos / antiguo | Neutro y texto explícito | Nunca usar verde ni una afirmación de disponibilidad. «Último dato conocido» se diferencia de «estado actual». |
| Error de interfaz | Rol de error de `ColorScheme`, revisado visualmente | Un fallo de carga o formulario no se confunde con severidad de incidente. |

Los hexadecimales describen la **base existente**, no una aprobación de todos sus pares. Antes de implementar se hará una matriz de contraste por combinación real, incluidos botones, chips, sobreimpresiones y estado deshabilitado. El color siempre tendrá redundancia textual o iconográfica.

### Tipografía, espacio, forma y profundidad

- **Tipografía:** partir de Manrope y la escala existente (`32/40`, `26/32`, `20/28`, `16/24`, `14/20`, `12/16`). Asignar cada nivel a un propósito, permitir el escalado del sistema y evitar introducir tamaños locales de 10 px para información útil. Reservar el nivel de mayor impacto para emergencia. Las etiquetas en mayúsculas existentes se revisarán caso por caso por legibilidad y lectura asistida; no son una obligación para texto largo. **Decisión D2 pendiente:** mantener Manrope o evaluar una alternativa mediante muestras comparables de Inicio, Alertas y Emergencia; no añadir otra fuente sin demostrar mejora.
- **Espaciado:** conservar la escala de 4, 8, 16, 24, 32 y 48 dp, margen lateral 20 dp y ancho máximo 600 dp como punto de partida. Usar el espacio para agrupar datos relacionados; una tarjeta nueva solo cuando aporte agrupación o interacción real. Evitar medidas ad hoc salvo restricciones de un componente.
- **Radios:** conservar 24 dp para tarjetas principales, 16 dp para botones/campos, 12/8/4 dp según densidad y píldora para estados. La forma comunica nivel y función; no imponer el mismo radio a toda la interfaz.
- **Elevación:** fondo plano, superficie por contraste tonal y sombra suave actual como máximo ordinario. La alerta crítica puede usar borde/acento para prioridad. Evitar brillo, desenfoque y sombras animadas sin necesidad demostrada.
- **Iconografía:** una familia coherente de `Icons` ya disponible, tamaño y grosor legibles, siempre con etiqueta para acciones importantes. No depender de un icono para comunicar el significado de un estado.

### Variantes mínimas de componentes

| Componente actual | Variantes o estados a especificar antes de extenderlo |
| --- | --- |
| `PrimaryButton`, `GhostButton`, `CriticalButton` | Normal, pulsado/foco, cargando, deshabilitado, error cuando corresponda. Texto que anuncie el resultado real de la acción. |
| `StatusPill` | Operativo confirmado, atención, crítico, desconocido y dato antiguo; icono o texto además del color. |
| `AttentionBanner` y tarjetas de alertas | Gravedad, tiempo conocido/desconocido, `queued`, cancelado, reconocido; no redefinir la clasificación vigente. |
| Cabeceras, tarjetas e indicadores de Inicio | Jerarquía uniforme y tratamiento explícito de carga/ausencia/frescura. |
| Campos y formularios | Foco, ayuda, validación, envío y error en lugar estable; compatibilidad con teclado y autocompletado. |
| `ComingSoonView` | Solo para módulos que aún no tienen implementación; no presentarlo como estado vacío de datos reales. |

El punto de integración será `AppTheme`/`ThemeData` y los archivos actuales de `lib/core/theme/`, con componentes compartidos en `lib/widgets/`. El tema cubrirá controles Material comunes; un widget específico mantendrá únicamente sus reglas distintivas. No se crea un segundo paquete de tokens ni una jerarquía de componentes abstracta sin consumidores.

## 3. Motion Design

**Principio:** cada movimiento muestra qué cambió, dónde quedó el contenido o qué acción se registró. Debe poder interrumpirse y no retrasar una alerta crítica, su lectura ni las acciones disponibles.

| Contexto | Propuesta inicial verificable | Límite |
| --- | --- | --- |
| Pulsación / selección | Retroalimentación Material inmediata; cambio de color, foco o estado en aproximadamente 100–200 ms. | La acción comienza al toque, sin esperar la animación. |
| Cambio local de contenido | Transición discreta de opacidad o tamaño en aproximadamente 150–250 ms cuando ayude a seguir el cambio. | Evitar movimiento de toda la pantalla por cada dato de RTDB. |
| Navegación ordinaria | Mantener transiciones de plataforma/go_router inicialmente; evaluar ajustes solo tras pruebas de continuidad. | La redirección de emergencia sigue siendo inmediata y prioritaria. |
| Emergencia | Aparición clara, estable y sin secuencia de entrada obligatoria. | Nada de cuenta regresiva, rebote o animación que postergue la información. |
| Estado persistente de atención | Revisar el pulso actual: conservarlo solo si aporta detección y pasa accesibilidad/rendimiento; preferir énfasis estático cuando se reduzca movimiento. | Nunca sugerir sincronía con buzzer o preaviso del SDA. |

Las duraciones son **parámetros de diseño candidatos**, no tiempos funcionales ni promesa de latencia. Se ajustarán con observación en dispositivo. Con la preferencia del sistema de reducir animaciones, las decorativas se eliminan y las explicativas se simplifican sin ocultar estados. No se propone portar los nuevos resortes de Material 3 por cuenta propia: la [guía actual de motion de Material](https://m3.material.io/styles/motion) señala que su implementación de física aún no está disponible para Flutter. **Decisión D3 pendiente:** aprobar esta política de movimiento sobrio o pedir una exploración visual alternativa antes de codificar.

## 4. UX, navegación y estados

- **Jerarquía:** primero incidente que requiere atención, luego estado y calidad de información, después detalles y acciones secundarias. En una emergencia, título y tipo, ubicación con su calidad/antigüedad, vehículo y acciones reales deben ser identificables sin explorar tarjetas técnicas. El orden final se validará con prototipos sin cambiar los datos que hoy se reciben.
- **Navegación:** preservar `GoRouter`, las cinco ramas del propietario, el control de sesión y la pantalla crítica fuera de la barra inferior. Las vistas por rol se diseñarán cuando los permisos y módulos de Fases 3–6 estén implementados; nunca mostrar al contacto controles técnicos del propietario. Mantener nombres y destinos estables para las mismas acciones. No introducir rutas ni deep links antes de su fase funcional.
- **Carga:** distinguir «todavía consultando» de «sin registros». Mantener contenido estable cuando una actualización parcial lo permita, pero no reutilizar un valor antiguo como actual sin etiqueta. El patrón concreto de carga depende del proveedor de cada pantalla.
- **Vacío:** explicar qué falta y qué se puede hacer ahora; no decir «todo en orden» cuando solo faltan datos. Un placeholder de módulo pendiente se rotula como tal.
- **Error:** indicar qué lectura o acción falló y, solo si existe una operación válida, cómo reintentar. No convertir un error de red en emergencia ni ocultarlo como ausencia de datos.
- **Éxito:** confirmar una acción únicamente cuando la fuente autorizada la confirme. En reconocimiento de incidente, conservar la actualización por flujo remoto actual, no una mutación optimista inventada.
- **Deshabilitado:** señalar por qué una acción no está disponible cuando sea relevante, sin prometer una capacidad futura. Un control sin implementación no debe presentarse como acción efectiva; su resolución pertenece a una tarea funcional separada.
- **Desconocido, antiguo y diferido:** usar texto inequívoco para tiempo ausente, posición sin `fix`, última ubicación conocida, dispositivo sin estado y `queued`. No inferir conectividad, ubicación actual ni recepción reciente a partir de un dato previo. No usar una hora de SDA, recepción o actualización como si fueran equivalentes.

**Pendientes funcionales separados:** «Ver mapa» y «LLAMAR A EMERGENCIAS» tienen callbacks vacíos; Inicio puede afirmar operación con información insuficiente; la etiqueta de origen actual no distingue SOS manual. Esta especificación registra esos hallazgos, sin autorizar su corrección ni definir el destino de las acciones. La frescura de datos y el mapa corresponden a Fase 5; la política final de procedencia MQTT/Iridium sigue pendiente de Fase 7. Cualquier texto o control que dependa de esas decisiones se revisará con su tarea funcional.

## 5. Accesibilidad y adaptación

- **Contraste:** objetivo mínimo 4,5:1 para texto ordinario y 3:1 para texto grande, siguiendo la guía citada de Flutter; verificar los pares reales en estados normal, atención, crítico y foco. Exigir también diferencia perceptible de iconos/bordes relevantes. Blanco sobre los acentos actuales ámbar o verde no se considera aprobado por defecto.
- **Objetivos táctiles:** área interactiva de al menos 48 × 48 dp en Android, incluso si el icono visible es menor. Separación suficiente para evitar toques involuntarios en emergencia. El foco de teclado debe verse y seguir orden lógico.
- **Semántica:** etiquetas claras para botones, estado y tiempo; ordenar lectura TalkBack como se ve la jerarquía; no anunciar dos veces texto decorativo; comunicar cambios importantes sin un flujo de anuncios que interrumpa la lectura. El color y el pulso no son el único canal.
- **Texto y dimensiones:** probar escala de texto normal y la máxima disponible en el dispositivo objetivo, pantalla Android pequeña y grande, orientación aplicable y teclado abierto. Permitir crecimiento vertical y desplazamiento; no truncar acciones, severidad, error ni calidad de ubicación. Las coordenadas pueden abreviarse visualmente solo si la información sigue accesible.
- **Interacción:** estados de foco, pulsado, carga y deshabilitado distinguibles; formularios con error asociado al campo; evitar cambios inesperados de contexto mientras se escribe. Probar con TalkBack y verificaciones de [accesibilidad de Flutter](https://docs.flutter.dev/ui/accessibility/accessibility-testing).

## 6. Rendimiento Flutter y medición

**Preventivo:** usar `const` cuando proceda, dividir por responsabilidad y frecuencia de cambio, mantener trabajo costoso fuera de `build`, observar solo el dato necesario con `Provider` cuando la medición lo justifique, usar listas perezosas si el volumen visible lo exige, evitar animar opacidad de grandes subárboles, desenfoques y recortes costosos, y disponer controladores/timers correctamente. Estas prácticas siguen las [recomendaciones de Flutter](https://docs.flutter.dev/perf/best-practices); no implican sustituir Provider ni añadir cachés por adelantado.

**Hipótesis a comprobar:** `HomeScreen` observa varios proveedores, `AlertsScreen` clasifica listas en `build`, algunas secciones generan todos sus hijos y `AttentionBanner` tiene un pulso continuo y un temporizador. La inspección estática no demuestra jank ni exceso de consumo. No se aprobará una refactorización de rendimiento solo por esas observaciones.

**Protocolo para una fase autorizada posterior:**

1. Usar escenarios ficticios reproducibles de `main_dev.dart` y registrar dispositivo, versión Android, frecuencia de pantalla, build, volumen de eventos y recorrido. Firebase real, SDA y bridge solo con autorización específica cuando la prueba los necesite.
2. Medir primero en dispositivo físico **en modo profile** con DevTools: Inicio en reposo y con actualización, desplazamiento de Alertas, cambio de pestañas, aparición/cierre de emergencia y movimiento del banner. Comparar con la misma ruta antes de cambiarla.
3. Registrar tiempos de fotograma de UI y raster, fotogramas fuera del presupuesto de la frecuencia real, reconstrucciones relevantes y, si procede, memoria/CPU. Usar emulador para corrección y exploración, no como evidencia principal de fluidez. [Perfilado oficial de Flutter](https://docs.flutter.dev/perf/ui-performance).
4. Corregir únicamente un cuello de botella localizado, volver a medir el mismo recorrido y conservar el cambio si mejora la causa sin degradar accesibilidad o funcionalidad. Si no hay problema medido, no añadir optimizaciones estructurales.

La prueba física y cualquier uso del SDA, bridge o servicios reales requerirán autorización específica conforme a `AGENTS.md`. El presupuesto por fotograma se calcula con la tasa del dispositivo (por ejemplo, 16,7 ms a 60 Hz); no se convierte en una promesa de que toda operación de red termine en ese plazo.

## 7. Arquitectura de componentes y secuencia incremental

1. **Cerrar decisiones D1–D3 y revisar muestras de tres pantallas.** Fijar una única tabla aprobada de roles y pares accesibles. Documentar qué parte de la referencia histórica queda vigente. Esta tarea es de diseño; no cambia comportamiento.
2. **Base visual compartida.** En una tarea de implementación posterior, ajustar los tokens y `AppTheme` existentes, después un componente a la vez. Conservar APIs de widgets salvo necesidad demostrada y aprobada. No crear una segunda capa de temas.
3. **Estados de componentes.** Aplicar variantes a botones, píldoras, tarjetas y formularios según sus consumidores reales. Verificar cada uno antes de extenderlo.
4. **Inicio y Alertas.** Adaptar composición, densidad, accesibilidad y motion sin alterar clasificación o repositorios. Los textos que dependan de frescura, mapa o acciones pendientes se tratan mediante la tarea funcional correspondiente del plan.
5. **Emergencia.** Ajustar presentación con regresión de disparo, cierre, `queued`, cancelación y reconocimiento. Nada de countdown o cancelación desde la app.
6. **Resto de módulos.** Diseñar e implementar cuando Fases 3–6 provean datos y permisos; usar los mismos componentes, sin duplicar pantallas por rol si no hay un motivo funcional o de accesibilidad.
7. **Medición y ajuste final.** Perfilado físico autorizado y correcciones basadas en evidencia, más comprobación visual y de accesibilidad en los recorridos principales.

Cada paso es una tarea revisable por separado. La aprobación de este documento no marca ninguna casilla funcional del plan como completada ni autoriza automáticamente el paso siguiente.

## 8. Criterios de aceptación

### Por componente

- Tiene propósito, variantes y estados documentados; usa roles aprobados y no colores o medidas arbitrarios.
- Contraste, objetivo táctil, foco, semántica y texto escalado verificados en sus combinaciones reales; no depende solo de color o movimiento.
- Responde de inmediato; cargando/deshabilitado/error no se confunden; una acción habilitada produce el comportamiento ya implementado y autorizado.
- No altera contratos de datos, clasificación o navegación; pasa las pruebas existentes pertinentes y las nuevas pruebas de accesibilidad que cubran un riesgo real.
- Si se anima, explica un cambio, se simplifica al reducir movimiento y no retrasa acciones críticas. El coste se mide cuando el componente afecta un recorrido sensible.

### Por pantalla

- Prioridad visual acorde al rol y al estado real; carga, vacío, error, desconocido, dato antiguo y `queued` distinguibles cuando correspondan.
- Funciona en pantalla pequeña, texto grande y con TalkBack; no hay desbordes ni controles inaccesibles en el recorrido principal.
- Mantiene rutas, redirecciones, permisos y acciones vigentes. La pantalla crítica aparece y se cierra bajo las mismas condiciones probadas.
- Se valida con capturas comparables, revisión de contenido, pruebas Flutter pertinentes y medición de fluidez en dispositivo físico cuando se autorice esa etapa. Un resultado de emulador no se presenta como prueba física.
- Se registran hallazgos funcionales fuera de alcance sin corregirlos dentro del rediseño visual.

## Decisiones requeridas antes de implementar

| ID | Alternativas a aprobar | Impacto |
| --- | --- | --- |
| **D1 Identidad** | A: Silent Guardian refinado (recomendada); B: precisión técnica; C: serenidad cálida. | Fija el carácter visual y cuánto cambia la paleta/superficie actual. |
| **D2 Tipografía** | Mantener Manrope (recomendada inicialmente); comparar otra fuente antes de decidir. | Afecta legibilidad, carga de fuentes y coste de revisión de todas las pantallas. |
| **D3 Movimiento** | Política sobria propuesta (recomendada); exploración de una variante con más expresión. | Afecta transiciones, pulso y alcance de pruebas de accesibilidad/rendimiento. |

Una vez elegidas D1–D3, aún se requiere autorización explícita para cualquier implementación Flutter. Las decisiones funcionales sobre acciones vacías, frescura, mapa, origen de transporte y módulos pendientes permanecen en sus fases respectivas.
