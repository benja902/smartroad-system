# Login Flutter — Silent Guardian: Refined / Signature

**Estado vigente: [Signature v2 predeterminada provisional](ADOPTION.md), aprobada por el usuario tras revisión en Edge.** La variante compartida y el arranque DEV usan Signature v2; Actual y Refined permanecen en el selector. No se activa D automáticamente en producción. El registro siguiente conserva la historia de propuestas, pruebas y capturas previas.

**Revisión posterior: [Signature v2 — hero y superficie integrada](SIGNATURE_V2.md).** El usuario revisó las tres variantes en Edge y no aprobó Signature v1. Las PNG y la tabla siguientes documentan esa primera iteración; no representan Signature v2. Se conservan sin regenerar. Actual sigue siendo predeterminada y Refined no se rediseña en v2.

## Registro de la primera iteración (histórico)

17 de octubre de 2026. **Alternativas experimentales DEV, pendientes de revisión humana en esa etapa.** No aprueban Design System v1.0 y no sustituyen Motion Prototype D. Base: checkpoints `d780464` (integración compartida/logout) y `85117fd` (fondo nativo DEV sin carretera anterior). La decisión vigente de adopción está enlazada al inicio de este documento.

## Plan de composición

Mantener la escena y marca originales como protagonista: una sola ilustración, perspectiva, escala final 1.0, trayectorias y reloj D intactos. La diferencia se concentra en la superficie que recibe esa escena y en la jerarquía del formulario. Se descartan tarjetas apiladas, blur, sombras genéricas, chips que sugieran conectividad real y nuevas acciones de acceso.

| Aspecto | Actual conservado | A — Silent Guardian Refined | B — Silent Guardian Signature |
|---|---|---|---|
| Superficie | Canvas `#F8F9FA` aprobado | Blanca, composición abierta y silenciosa | Blanca con un plano Aqua suave que sigue la diagonal de la carretera |
| Bienvenida | 32/1,3, descripción en dos líneas fijas | Manrope 32/1,2, texto fluido y espacios afinados | Manrope 34/1,2, «Bienvenido / a URBES.», mayor presencia editorial |
| Campos | Etiquetas en mayúsculas, sin iconos | Sentence case persistente, correo/candado outline, fondo blanco | Misma estructura y familia de iconos, superficie muy clara, foco Teal |
| Contraseña | Oculta, sin control de revelado | Ojo de 48×48 dp con nombre y estado | Mismo componente e interacción |
| Acción | Navy, presentación aprobada | Navy, mínimo 60 dp, foco visible y feedback discreto | Misma acción; Aqua/Teal complementan la composición, no reemplazan Navy |
| Estados | Comportamiento aprobado | Foco, errores reales, carga/deshabilitado | Los mismos estados funcionales |

Composición común: marca superior izquierda → escena isométrica → bienvenida alineada a izquierda → correo/contraseña → acción. No hay otro formulario ni controles ficticios. Las tres referencias propias de revisión son [Actual](current.png), [Refined](refined.png) y [Signature](signature.png).

## Selección y revisión

```powershell
flutter run -d edge -t lib/main_dev.dart --no-pub
```

Después de terminar u omitir D, abrir el icono de ajustes de la cabecera, tooltip **Comparar Login: Actual**. Elegir **Actual**, **A · Refined** o **B · Signature**. El mismo control funciona en la revisión aislada del panel DEV. No hay ruta, página HTML ni reproductor adicional.

El selector es exclusivamente DEV, no persiste entre ejecuciones y comienza en Actual. Cambiar de alternativa conserva el mismo `FormState`, los controladores y los datos; no reproduce D. La contraseña vuelve a ocultarse al cambiar de alternativa. Cerrar sesión conserva el destino estático y permite seguir comparando; el panel mantiene la reproducción manual anterior.

Se usa [MenuAnchor de Material 3](https://api.flutter.dev/flutter/material/MenuAnchor-class.html) sobre el Overlay existente. La revisión aislada del panel no posee Navigator; no se introduce uno para el selector. La prioridad crítica retira también el menú abierto al cerrar la revisión.

Para estados reales con mocks: enviar vacío para validar; enfocar cada campo; introducir solo datos ficticios; alternar el ojo; enviar para observar el acceso mock. El mock habitual puede completar demasiado rápido para apreciar la carga: se prueba mediante un repositorio controlado exclusivamente en tests, sin añadir latencia artificial al producto ni modificar repositorios. No hay Google/Apple ni enlaces de operaciones no implementadas.

SDA apagado, bridge detenido, Firebase real sin uso; no hace falta celular. Internet solo puede ser necesario para la fuente Google Fonts ya usada por la aplicación; estas alternativas no añaden descargas. La evidencia automatizada usa Manrope local únicamente en QA.

## Tokens y componentes

`login_visual_style.dart` contiene una receta local de presentación opcional, no un segundo tema global. Parte del `ThemeData` existente y reutiliza `AppColors` para neutros, `AppSpacing`, `AppRadius` y `AppTypography` (Manrope). Los roles provisionales proceden de la propuesta DS existente:

- Navy oficial `#031B3B`; Aqua oficial `#14E0D3`, sin editar el isotipo.
- Teal interactivo `#006D68`; error UI `#B52F34`, diferente del rol de incidente.
- Superficie blanca; plano ilustrativo `#E4F5F1`; campo Signature `#F5FAF9`.
- Borde de control `AppColors.outline` (`#75777E`); foco/error 2 dp; botón enfocado con borde Teal 3 dp.
- Radios de control 16; campos ≥60 dp; iconos 22 dp y objetivos de toque ≥48 dp. Controles y textos pueden crecer; no se limita el escalado al 200 %.
- Margen 20 dp a ≤360 y 24 dp en anchos mayores; formulario limitado a una columna cómoda en escritorio. El scroll común conserva el encuadre antes de descontar teclado.

No se edita `AppTheme`, ni se promueven estos valores a tokens globales. Tras elegir dirección, consolidar los roles aprobados en la arquitectura existente, no mantener catálogos paralelos permanentes.

`LoginScreen` sigue siendo dueño de campos, validadores, envío, autofill, errores y controladores. Solo recibe presentación opcional mediante `LoginVisualScope`. El ojo es la interacción de presentación autorizada en este encargo, inicialmente oculto; no cambia la contraseña ni la transmite a otro sitio. `PremiumLoginForm` y `PremiumLoginPresentation` se reutilizan en las tres alternativas. `PrimaryButton` añade un indicador de carga opcional; sus consumidores habituales conservan el valor predeterminado anterior.

## Motion y continuidad

- Escenario, vehículo, baliza, vuelo/reunión de marca y traslado: tiempos y funciones D conservados.
- Inicio del formulario: 4090 ms; campos: 4130 ms; acción: 4170 ms. Entradas de 240 ms cúbica de salida con desplazamiento 6 px, como antes. Fin 4440 ms.
- El tratamiento de superficie experimental entra con opacidad 4090–4330 ms, usando el mismo reloj; no oculta ni recrea la ilustración o la marca. Antes de 4090 el fondo es el aprobado `#F8F9FA`.
- Botón: feedback Material de estados, 120 ms; sin escalado, sacudida o espera. Ojo inmediato y semántica actualizada. Cambiar de variante no añade una animación de entrada.
- Movimiento reducido: destino inmediato por el host existente, feedback de botón sin transición; progreso ocupado estático. Sin bucles decorativos ni efectos costosos. La animación de carga normal solo indica una operación en curso.

La única extensión del artboard es un color de fondo opcional, con el valor aprobado intacto por defecto. Las alternativas usan fondo transparente para componer la superficie detrás; geometría, pintores de marca, recursos y modelos de movimiento no se recolorean ni se modifican.

## Validación y límites

**99 pruebas distintas satisfactorias:** 80 regresiones existentes y 19 de alternativas. La ejecución conjunta inicial pasó 98 pruebas; la comprobación adicional del panel descubrió que un PopupMenuButton requería Navigator, por lo que se reemplazó por MenuAnchor sobre el Overlay existente. Las 19 pruebas finales de alternativas volvieron a pasar sin avisos de hit-test, incluido menú abierto al llegar una emergencia. No se crea una ruta para resolverlo.

Cobertura nueva: selector en ruta y panel, un único formulario, datos conservados, contraseña oculta/revelada, validación real, foco, autofill, errores/carga, 320/360/390 dp a 100/200 %, teclado, reducción de movimiento y contraste. Las regresiones existentes comprueban D, logout sin replay, reproducción manual, omisión, segundo plano y emergencia. No se repiten builds Android ni se usa hardware.

La exportación opcional pasó y produjo las tres capturas enlazadas, inspeccionadas visualmente. Se cargan Manrope y Material Icons locales solo en el runner de QA; no se modifican fuentes o assets de ejecución. La fuente Material de fallback en estas evidencias es Manrope: las métricas del runtime real siguen sujetas a revisión en Edge/Android.

Auditoría Git: `_submit` y `_messageFor` iguales al checkpoint; modelos de movimiento, geometría generada, marca y recursos HTML intactos. Sin cambios en `main.dart`, temas globales, router, proveedores, repositorios, Android/web ni manifiestos de dependencias. `git diff --check` satisfactorio.

**Análisis estático de ocho objetivos: cero incidencias.** Incluye entrada DEV, módulo auth, selector/host, escena, botón y las dos suites modificadas. La corrección de una regla de llaves en el exportador QA no cambia su comportamiento.

**Edge pendiente de comprobación efectiva:** el intento con consola PTY falló al crear PowerShell (acceso denegado, antes de ejecutar Flutter). Se reintentó con `cmd` y el comando de revisión indicado: llegó a «Launching lib/main_dev.dart on Edge in debug mode» / «Waiting for connection from debug service on Edge», sin nueva salida durante 60 segundos. Se interrumpió conforme a `AGENTS.md`. No se atribuye la detención a un fallo de la aplicación sin evidencia, ni se considera acreditado el arranque web/Hot Reload con las pruebas VM. No se cambió la configuración de Edge o del proyecto para sortearlo.

Las imágenes propias se generan opcionalmente, sin nuevos assets de ejecución:

```powershell
flutter test --no-pub -r expanded --dart-define=URBES_EXPORT_LOGIN_VARIANTS=true test/login_visual_variants_test.dart
```

Son capturas Flutter VM con Manrope local y fallback Material de QA; no certifican métricas exactas de fuentes en Edge/Android, TalkBack, autofill de sistema, navegación con teclado externo ni rendimiento físico. No hay nuevas dependencias, servicios reales, commits ni push. La revisión humana de dirección artística queda pendiente.

## Archivos del incremento

| Archivo / grupo | Cambio |
|---|---|
| `lib/screens/auth/login_visual_style.dart` | Recetas locales, enum y scope de presentación opcional. |
| `lib/screens/dev/dev_login_variant_menu.dart` | Selector DEV Material 3 sobre Overlay. |
| `lib/main_dev.dart`, `lib/screens/dev/brand_intro/dev_brand_intro.dart` | Habilitación y selección en el host existente; reloj D y reglas de arranque/logout intactos. |
| `lib/screens/auth/login_screen.dart` | Decoración opcional, estado del ojo y carga visual; misma validación/envío. |
| `lib/screens/auth/premium_login_form.dart` | Misma estructura/entradas, jerarquía y espacios parametrizados. |
| `lib/screens/auth/premium_login_presentation.dart` | Tema local, superficie y selector, scroll y composición compartidos. |
| `lib/presentation/premium_scene/premium_scene.dart`, `premium_closure_preview.dart` | Propagación de fondo opcional para componer detrás, con predeterminado conservado. |
| `lib/widgets/primary_button.dart` | Estado de carga opcional; consumidores anteriores intactos. |
| `test/login_visual_variants_test.dart`, `test/premium_login_route_test.dart` | Cobertura nueva y habilitación opcional de revisión en el helper de ruta. |
| `docs/PREMIUM_SPLASH_LOGIN_FLUTTER_SPEC.md` | Enlace a esta revisión y alcance provisional. |
| Esta carpeta | Informe y tres capturas propias; sin nuevo prototipo HTML. |

Pendientes de aprobación: elegir A/B o ajustes dentro de esta comparación; ratificar tamaños/roles; teclado y autofill reales, TalkBack y perfilado físico en una etapa autorizada. No avanzar automáticamente a otras pantallas ni al tema global.
