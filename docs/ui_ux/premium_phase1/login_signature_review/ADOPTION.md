# Adopción provisional — Login Silent Guardian Signature v2

17 de octubre de 2026. El usuario revisó Signature v2 en Edge y autorizó su adopción como diseño predeterminado provisional compartido del Login. Este hito conserva las variantes y permite avanzar posteriormente a Inicio; no autoriza implementar Inicio en este checkpoint, desplegar, cambiar autenticación o aprobar el Design System global.

## Configuración compartida

`LoginVisualVariant.defaultVariant` es `signature`. `LoginVisualScope.variantOf` lo utiliza cuando no hay selección explícita y `PremiumLoginPresentation` consulta esa misma función. El host DEV inicializa su selección con el mismo valor. No hay flags diferentes de diseño por entrypoint ni un segundo formulario.

- `main.dart` permanece intacto: su `LoginScreen` usa Signature v2 estática a través de la presentación compartida. No instala el host ni reproduce D automáticamente.
- `main_dev.dart` conserva el host y mocks existentes. Al abrir sin sesión usa Signature v2; D se reproduce únicamente en su arranque y en las revisiones manuales ya autorizadas.
- El selector DEV mantiene Actual, A · Refined y B · Signature v2. Cambiar la selección conserva los datos y el mismo `FormState`; no reinicia la secuencia. Es una selección de revisión, sin persistencia ni cambio del router.
- Cerrar sesión desde Perfil vuelve directamente al Login final, sin repetir D. El listener de sesión y las reglas de navegación no se modifican.
- Hot Reload puede conservar la selección previa del host ya abierto. Elegir Signature v2 en el selector para esa sesión, o reiniciar DEV para comprobar el predeterminado de arranque; no se fuerza la pérdida de estado para cambiarlo.

## Alcance del checkpoint

Mensaje autorizado: `feat(ui): establece Signature v2 como Login predeterminado`.

Incluye la etapa visual pendiente desde `85117fd`: recetas locales de estilo, selector DEV, iconos/etiquetas/ojo de contraseña, presentación y formulario compartidos, carga opcional del botón, fondos opcionales de la escena, composición hero/panel Signature v2, predeterminado compartido, pruebas y documentación. Los modelos D y geometrías generadas permanecen iguales. Las PNG propias de la primera comparativa se conservan como evidencia histórica, claramente identificadas; no se regeneran ni representan v2.

No incluye cambios en `main.dart`, Android, web, Firebase, repositorios, proveedores, router, configuración privada, dependencias o tema global. No hay artefactos de compilación, recursos de terceros añadidos, cachés o capturas redundantes. No hay push.

## Validación de esta adopción

Pruebas dirigidas: `login_visual_variants_test.dart`, `premium_login_route_test.dart`, `premium_login_test.dart` y `motion_pilot_test.dart`. Cubren entrada DEV real y sesión mock sin autenticar, presentación Signature estática sin host, selector y datos conservados, Perfil/logout sin replay, revisión manual, montaje/tiempos de handoff, validadores/autofill/envío/errores/carga, teclado y texto 200 % a 320/360/390 dp, movimiento reducido, segundo plano y prioridad crítica. No se repite toda la batería D: sus modelos/recursos no se modifican y se conserva la cobertura de continuidad existente.

**43 pruebas dirigidas satisfactorias**; una exportación de QA omitida deliberadamente. El análisis estático se limita a los archivos Dart afectados. Auditoría Git de 19 archivos, sin recursos >=1 MB, patrones de claves privadas/tokens ni cambios ajenos. `git diff --check` satisfactorio; revisión de índice y `git diff --cached --check` antes del checkpoint. No se abre Edge, genera capturas o utiliza hardware/servicios reales en esta adopción; la aprobación visual procede de la revisión humana previa.

**Análisis estático de ocho objetivos: cero incidencias.** Cubre los componentes Dart de presentación, host/selector, botón, entrada DEV y las dos suites modificadas. Las pruebas de ruta existente pasan con el nuevo predeterminado, sin cambios de autenticación/navegación.

## Pendientes registrados, sin implementar

- Elegir biblioteca definitiva de iconos: evaluar Lucide, Phosphor u otra alternativa frente a Material existente, coherencia, licencia y coste; sin nuevas dependencias ahora.
- Refinar tipografía y controles: escala, pesos, etiquetas, bordes y consistencia de estados.
- Aprovechar mejor el espacio vertical sin alterar el encuadre ni los tiempos D aprobados.
- Evaluar microinteracciones adicionales con propósito, respetando movimiento reducido e inmediatez de incidentes.
- Validación física Android del Login adoptado, teclado/autofill y rendimiento; no se equipara fluidez VM/web a rendimiento físico.
- Revisión final de accesibilidad: TalkBack, foco con teclado externo, contraste de todos los estados, escalado y objetivos táctiles.
- Consolidación posterior del Design System global mediante AppTheme/ThemeData y tokens existentes. Esta aprobación del Login no aprueba automáticamente otros componentes/pantallas.

Siguiente etapa, aún sin implementar aquí: analizar Inicio con Silent Guardian — Signature en Flutter DEV/Hot Reload, preservando su lógica funcional. Para revisión local: Edge/DEV con mocks; SDA apagado, bridge detenido, celular innecesario y Firebase real sin uso. Internet solo si lo necesita el mecanismo de fuentes ya existente.
