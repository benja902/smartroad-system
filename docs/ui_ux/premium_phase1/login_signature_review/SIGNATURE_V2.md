# Silent Guardian — Signature v2

**Aprobada por el usuario en Edge como diseño predeterminado provisional del Login.** [Adopción compartida y pendientes](ADOPTION.md). No implica aprobación final del Design System global o rendimiento Android. Evolución de la misma opción **B · Signature v2**, no una cuarta alternativa. El usuario no aprobó Signature v1. El registro de construcción que sigue se realizó sin abrir navegador ni generar capturas; la revisión visual posterior fue humana.

## Análisis de continuidad previo

La ilustración y la marca pertenecen a un único `PremiumClosureArtboard`. Cambiar su encuadre para introducir un hero nuevo produciría un salto respecto a D. Se mantiene el artboard, su ajuste uniforme y todos sus relojes. El cierre conserva origen de escena (14,71), escala 0,6 y lockup final en cabecera.

La composición cambia detrás y debajo: un fondo frío neutro recibe la escena, y una superficie blanca de formulario se integra a ese mismo fondo mediante esquinas superiores de 32 dp y una sombra de contacto tenue. Sin curva Aqua, franja turquesa, otro logo, contenedor de ilustración adicional ni desplazamiento nuevo de la escena.

En coordenadas de referencia 390×844, el panel comienza en y=312 y su padding superior es 28: el título continúa en y=340. La evidencia existente de D muestra el último píxel visible de ilustración en y=291 antes del formulario; el panel deja aproximadamente 20 px de separación y su borde/sombra no tapa la carretera o los objetos. Esta comprobación usa la PNG propia ya existente; no se generó otra. Las medidas se adaptan con el mismo `fit`; teclado y texto grande conservan un scroll común.

La superficie se desvanece de transparente a opaca con el reloj existente 4090–4330 ms (cúbica de salida). Antes del handoff se conserva el fondo de arranque aprobado. El formulario sigue montándose en 4090 ms; título, campos y acción mantienen sus entradas originales. La opacidad del panel afecta únicamente a su fondo: no multiplica la de los campos ni bloquea su interacción. Omisión y movimiento reducido llegan directamente al estado final por las garantías existentes.

## Decisiones de composición

- **Hero:** fondo continuo `#EDF3F5`, rol neutro ya contemplado en la propuesta DS. La escena D aporta el color y los objetos reconocibles. No se añaden adornos o más acentos.
- **Plano inferior:** una sola superficie blanca que llega hasta el fondo y crece con el contenido; esquinas superiores de 32 dp. Sombra estática Navy al 4 %, radio 16, desplazamiento −3: únicamente para separar ambos planos, sin blur de imagen ni filtros.
- **Jerarquía:** «Bienvenido.» en una línea a 32 dp, alineada con descripción/campos; elimina el salto editorial forzado de Signature v1 y recupera espacio para el formulario.
- **Controles:** se conservan iconos, etiquetas persistentes, ojo de contraseña, contraste, foco Teal, acción Navy y estados de error/carga de la iteración anterior.
- **Variantes:** únicamente Signature activa el panel y el fondo nuevo. Actual y Refined mantienen sus composiciones para comparación DEV. Tras la aprobación humana, Signature v2 pasa a ser predeterminada compartida; el Splash continúa limitado a DEV. No cambian Auth, repositorios, router, Firebase o tema global.

## Revisión Actual / Refined

Se investigó la igualdad comunicada por el usuario sin regenerar archivos. Las PNG locales tienen hashes distintos y difieren en 237986 de 329160 píxeles (72,30 %, incluyendo el cambio de canvas); por tanto, los archivos guardados no son duplicados. Refined conserva casi toda la disposición de Actual, lo que limita el cambio compositivo percibido. Su diferencia visual verificable está en fondo blanco, iconos de correo/candado, etiquetas sentence case persistentes, ojo y acabado de controles.

La prueba del selector ahora verifica tanto el valor de `LoginVisualScope` como los controles efectivos: Actual muestra `CORREO`, sin correo outline u ojo; Refined muestra `Correo electrónico`, icono y ojo. Cambiar de opción conserva `FormState`, datos y reloj final. No se reprodujo una selección equivocada en estas pruebas; no hay evidencia para atribuir lo observado en Edge a caché u otra causa concreta. Refined permanece sin rediseñar.

## Validación dirigida

**20 pruebas satisfactorias**, con una prueba nueva de continuidad y aserciones ampliadas del selector. La exportación opcional se omite. Incluye:

- Panel en y=312, ancho completo y altura hasta el fondo, con artboard invariable en 4089/4090/4210/4330/4440 ms; escala de escena 0,6 y un único pintor de marca.
- Formulario ausente en 4089 y montado en 4090; opacidad de panel 0 / 0 / 0,875 / 1 / 1 en esas muestras.
- Conservación de formulario, datos, selección real de variantes y presentación habitual sin DEV.
- 320/360/390 dp, texto 100/200 %, teclado y scroll; visibilidad de contraseña, validadores, autofill, foco, error y carga.
- Movimiento reducido y retirada de revisión/menú por emergencia.

```powershell
flutter test --no-pub -r expanded test/login_visual_variants_test.dart
flutter analyze --no-pub lib/screens/auth/premium_login_presentation.dart lib/screens/auth/premium_login_form.dart lib/screens/auth/login_visual_style.dart test/login_visual_variants_test.dart
```

No se repitió la batería completa de regresión, ni se ejecutó Android, Edge o exportación de imágenes al construir v2. Compatibilidad geométrica/temporal verificada en tests; el usuario completó posteriormente la revisión visual en Edge y aprobó la adopción provisional. La validación física Android y accesibilidad final siguen pendientes.

**Análisis estático de los cuatro objetivos: sin incidencias.** `git diff --check` satisfactorio; PNG anteriores conservadas byte a byte. Los modelos y recursos de D permanecen intactos respecto al checkpoint y las extensiones opcionales de fondo del incremento anterior no se modifican aquí.

## Archivos de este incremento

1. `lib/screens/auth/premium_login_presentation.dart`: panel integrado, fondo continuo, composición común sin duplicar formulario y eliminación de los trazados decorativos anteriores.
2. `lib/screens/auth/premium_login_form.dart`: título de Signature sin salto forzado; Actual/Refined mantienen su tipografía y contenido.
3. `lib/screens/auth/login_visual_style.dart`: superficie hero neutra, solo consumida por Signature.
4. `test/login_visual_variants_test.dart`: comprobaciones de selección visible y continuidad del panel.
5. `REVIEW.md` y este informe: primera iteración identificada como histórica y decisiones v2 pendientes.

El resto de los cambios locales del incremento anterior permanece intacto. Geometría, trayectorias, funciones de movimiento, tiempos D y código funcional del Login no se editan. Sin dependencias nuevas, HTML, commits ni push.

## Cómo revisarla

Con DEV ya abierto en Edge, aplicar Hot Reload. Signature v2 queda seleccionada por defecto en ejecuciones nuevas; si el estado conservado de Hot Reload tenía otra elección, elegir **B · Signature v2** en el selector existente. Para revisar la entrega desde D: entrar con mock al panel y usar **Reproducir Splash → Login real DEV**; conserva Signature seleccionada. Actual y Refined siguen disponibles. Comparar también tras omitir y al volver del teclado.

SDA apagado, bridge detenido, celular innecesario; Edge/DEV abierto con mocks, sin Firebase real. Internet solo si el mecanismo de fuentes ya existente lo necesita. Detenerse en la revisión de Signature v2 antes de más cambios de dirección o producción.
