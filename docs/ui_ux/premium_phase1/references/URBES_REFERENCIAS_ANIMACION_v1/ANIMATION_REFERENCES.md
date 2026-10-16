# URBES Premium Redesign — Referencias y especificación de movimiento (v1)

**Estado:** referencia para prototipado, **NO aprobada para implementación**. 14 de octubre de 2026.  
**Ámbito:** Splash Screen / Brand Intro 01, transición al destino y Login.  
**Fuente:** tres videos MP4 suministrados por el usuario, análisis visual de secuencias y auditoría diferencial de Codex. No se dispone del código fuente de esas aplicaciones externas. Las técnicas mencionadas son hipótesis de implementación, no conclusiones sobre el código original.

## 0. Antes de empezar: hallazgos de la auditoría del proyecto

Codex inspeccionó el proyecto local e informó:

- El `Brand Intro 01` está **solo en DEV**, dibujado con `CustomPainter`, con carretera que se transforma en escudo, vehículo cenital, nodos y trazado del nombre URBES. Duración efectiva actual: **1900 ms**.
- El splash existente contempla primer fotograma rasterizado, toque para omitir, movimiento reducido, segundo plano y prioridad de un incidente crítico. **Preservar estas garantías**.
- Existe un arranque Android DEV estático (`debug` y `profile`) que debe enlazar visualmente con Flutter.
- El `LoginScreen` de Flutter tiene formulario, validación, errores, autofill y `PrimaryButton`; NO reconstruir lógica.
- `ScreenEntrance` / `EntranceSection` usa 240 ms, 8 dp y opacidad 0,85→1 para entradas de contenido; se puede aprovechar en controles, no como motor de escenas.
- Existe una propuesta de Login en HTML con camino, escudo y jerarquía visual. El Splash es DEV; el Login Flutter es compartido, por lo que cualquier **variante experimental del Login debe aislarse en DEV**.
- Hay una deficiencia de orquestación: el Login puede consumir su animación mientras está tapado por el splash. El objetivo es **coordinar la entrega visual**, no tocar autenticación o router.
- D1–D3 del diseño global siguen pendientes de aprobar. No hay evidencia para adoptar Rive/Lottie ahora.

Archivos conocidos del proyecto (verificar existencia): `AGENTS.md`, `docs/URBES_BRAND_INTRO_01.md`, `docs/URBES_MOTION_PILOT_01.md`, `docs/UI_UX_PHASE1_SPEC.md`, `docs/ui_ux/premium_phase1/REVIEW.md`, `lib/screens/auth/login_screen.dart`.

## 1. Referencia principal: Beeway

**Archivo:** `videos/01_beeway.mp4` — duración aprox. 19,9 s.  
**Resumen en imágenes:** `fotogramas/01_beeway_secuencia.png`.

**Observación de la secuencia original (tiempos aproximados):**

| Momento del video | Evidencia visible | Qué nos interesa | Qué NO debemos copiar |
|---|---|---|---|
| ~1,0–1,8 s | Personaje, suelo, edificios y nombre aparecen en momentos sucesivos | Entrada escalonada por capas, buen equilibrio espacial | Personaje, marca y texto ajenos |
| ~2,2–3,0 s | Teléfono/mapa entra desde la izquierda | Desplazamiento coordinado, superposición entre elementos | El teléfono tal cual |
| ~3,6–4,3 s | Taxi y marcador entran al escenario | Un vehículo aporta narrativa y dirección | Taxi amarillo, íconos y estilo de marca exactos |
| ~4,3–6,2 s | Ilustración y marca quedan estables | Pausa legible de cierre de marca | Duración prolongada si retrasa acceso URBES |
| ~6,3–7,3 s | La composición anterior se superpone y desvanece hacia login con ciudad isométrica | Transición fluida y continuidad estética | Copiar la ciudad, edificios y layout exacto |

**Prioridad alta para URBES:** composición ilustrada premium, elementos separados en capas, revelado progresivo, transición Splash→Login, una escena superior con carácter en el login.

**Punto de diseño por decidir:** preservar el lenguaje lineal de URBES o evolucionar hacia una ilustración con profundidad isométrica. No mezclar estilos incompatibles.

## 2. Referencia complementaria: Parcel

**Archivo:** `videos/02_parcel.mp4` — duración aprox. 17,7 s.  
**Resumen en imágenes:** `fotogramas/02_parcel_secuencia.jpg`.

- ~1,0–2,0 s: vehículo pequeño aparece en calles claras, visto desde arriba.
- ~1,8–4,5 s: se perciben cambios de posición y **orientación del vehículo** junto con desplazamientos/giros del escenario.
- ~2,5–4,5 s: el nombre de marca convive con movimiento de calles y vehículo.
- ~4,5–5,7 s: desvanecimiento y paso al login.

**Prioridad alta para URBES:** recorrido con curvas y rotación coherente del vehículo; sensación de ruta real sin motor 3D. Si se implementa en Flutter, puede evaluarse `PathMetric.getTangentForOffset`, siempre tras aprobar la trayectoria visual. No supone que Parcel usó esa técnica.

**Evitar:** copiar moto, calles o marca Parcel; desplazar constantemente todo el fondo si distrae del formulario o degrada rendimiento.

## 3. Referencia complementaria: Skyward

**Archivo:** `videos/03_skyward.mp4` — duración aprox. 16,8 s.  
**Fotogramas:** `fotogramas/03_skyward_splash.jpg` y `04_skyward_login.jpg`.

- ~1,2–3,9 s: un avión recorre una órbita alrededor del planeta con trayectoria punteada y revelado de marca.
- ~3,8–4,5 s: el splash desaparece mientras aparece la ilustración del login.
- ~4,1–5,5 s: avión pequeño cruza el paisaje superior del login; secuencia escalonada de título/campos/acciones.
- ~9,8–12,7 s: durante autenticación aparece una ilustración de carga coherente con el motivo del avión.

**Prioridad para URBES:** reutilizar un motivo gráfico (ruta, vehículo, marcador) en splash y cabecera del login; animaciones de carga solo si tienen sentido funcional; identidad de movimiento coherente.

**Evitar:** órbita planetaria o un avión en URBES; bloquear las solicitudes reales con tiempos decorativos.

## 4. Propuesta creativa para URBES — para validar, no implementar

**Dirección recomendada:** Beeway como **lenguaje de composición**, Parcel como **movimiento del vehículo**, Skyward como **continuidad entre pantallas**. Identidad URBES: seguridad vial, ruta, vehículo, conectividad/ubicación, escudo y nombre URBES. No se copian ilustraciones ni marcas.

### 4.1 Splash propuesto (storyboard sin tiempos cerrados)

1. **Arranque:** respetar continuidad del splash Android con el primer fotograma Flutter; fondo y geometría maestra coherentes.
2. **Construcción del paisaje/ruta:** aparecen progresivamente carretera, relieve o elementos viales (si aportan), evitando un inventario excesivo de decoración.
3. **Entrada del vehículo:** un vehículo cenital recorre parte de la curva; su orientación sigue la tangente, sin saltos entre segmentos.
4. **Ubicación/protección:** los elementos de ruta/conectividad se reorganizan para dar paso al escudo; conservar, donde resulte compatible, el concepto actual carretera→escudo.
5. **Cierre de marca:** URBES legible, con suficiente reposo; no sacrificar lectura por efectos.
6. **Entrega al destino:** elementos compartidos pasan a una posición/escala coherente o se desvanece la escena mientras aparece la ilustración superior de Login. Si la sesión ya está abierta, transición apropiada al destino real, sin forzar Login.

**Duración:** el sistema actual dura 1900 ms. Evaluar dos montajes en prototipo —uno próximo al actual y otro ligeramente más elaborado— antes de decidir. No aumentar espera por estética; preservar omisión, acceso crítico y movimiento reducido. Los rangos de los videos externos NO son objetivos de duración.

### 4.2 Login propuesto

- Preservar el formulario Flutter existente: campos, `PrimaryButton`, validación, errores, autofill, visibilidad de contraseña, teclado, accesibilidad.
- Rediseñar **principalmente la zona ilustrada**, con composición vial premium: carretera/vehículo/marcador/escudo en un estilo consistente, no una ciudad de taxi literal.
- El motivo visual compartido con splash continúa en la cabecera, con movimiento breve y discreto solo si no distrae.
- Aplicar `EntranceSection`/animación escalonada a título y formulario **cuando sean visibles**, no detrás del overlay del splash.
- Diseñar de forma explícita los estados: inicial, teclado visible, error, carga, sesión abierta y movimiento reducido. Una autenticación rápida no debe esperar por terminar una animación decorativa.
- Usar variantes DEV sin cambiar el Login compartido ni la autenticación principal hasta aprobación.

### 4.3 Componentes y recursos previstos (sujetos a prototipo)

- Geometría maestra de escudo, nodos y `URBES`.
- Vehículo cenital (punto pivote/rumbo documentado); no confundir con vehículo lateral existente en Inicio.
- Camino vectorial (eje, bordes, marcas) diseñado junto con trayectoria del vehículo.
- Escena/ilustración de Login consistente con la del splash.
- Composición estática equivalente para movimiento reducido, y fotograma inicial compatible con Android DEV.
- Tokens de movimiento, duraciones y curvas compartidos solo donde tengan consumidores reales.

**Recomendación técnica actual:** Flutter nativo (`CustomPainter`, `AnimationController`, transiciones), reutilizando la base auditada; SVG como fuente de diseño si conviene. No instalar `flutter_svg`, Rive ni Lottie por anticipado. Decidir después del prototipo y medición.

## 5. Restricciones funcionales y de calidad (no negociables)

1. No modificar código, paquetes, rutas, Firebase, bridge, reglas, firmware ni lógica de autenticación durante la fase de referencias.
2. Conservar omisión del splash por toque, movimiento reducido, segundo plano y prioridad del incidente crítico; no añadir latencia artificial a una emergencia.
3. Respetar el aislamiento experimental DEV y la continuidad Android nativo→Flutter.
4. Evitar ejecución escondida de la entrada del Login bajo el overlay, verificando el momento real en que queda visible.
5. Reutilizar Design System (colores, Manrope, radios, espacios y botones) y revisar decisiones D1–D3 pendientes; no crear sistema paralelo.
6. Diseñar para tamaños pequeños, texto grande, accesibilidad, teclado, autofill y estados reales.
7. Medir UI/raster, estabilidad y duración real en profile, sobre dispositivo físico solo cuando se autorice. Pruebas previas no garantizan fluidez del nuevo diseño.
8. Los videos son **referencias internas**, no recursos para incluir en la app, redistribuir públicamente o imitar pixel por pixel. Verificar procedencia/licencias de cualquier asset nuevo.

## 6. Entrega solicitada a diseño/Codex (sin implementación)

Preparar para revisión humana:

1. Matriz **conservar / mejorar / sustituir / falta decidir** entre Brand Intro 01 y propuesta premium.
2. **Dos composiciones estáticas** de Splash: A) composición progresiva por capas, B) recorrido cenital más protagonista.
3. **Una composición estática** de Login que reutilice geometría de la propuesta ganadora.
4. **Storyboard** con fotogramas clave de Splash→Login (o Splash→destino cuando ya hay sesión); especificar exactamente qué elemento continúa entre pantallas.
5. Recursos gráficos necesarios y decisión justificada de herramientas. Nada de descargar paquetes aleatorios antes de aprobar perspectiva y estilo.
6. Riesgos de arranque, superposiciones, test de movimiento reducido e interrupciones por incidentes críticos.

**Puerta de aprobación:** no producir cambios en el código de URBES antes de que el usuario apruebe las composiciones y storyboard.

## 7. Documentación de apoyo y alcance

- `fotogramas/05_urbes_login_prototipo.png`: captura de la propuesta visual existente proporcionada por el usuario; sirve para comparación y no prueba que el Login Flutter ya haya sido rediseñado.
- Los tiempos son **estimaciones de observación** en videos, no una especificación de timings exactos ni prueba de paquetes usados por sus autores.
- Ante discrepancias entre este documento y `AGENTS.md` o decisiones funcionales aprobadas, consultar y proponer reconciliación antes de actuar.
