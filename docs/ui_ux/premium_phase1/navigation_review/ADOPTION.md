# Pill Active — adopción compartida

El usuario revisó las alternativas en Edge y aprobó Pill Active como navegación predeterminada de URBES dentro de Silent Guardian — Signature. Aprobación visual, sin despliegue. El Design System global todavía requiere consolidación.

## Configuración y contrato conservado

`NavigationPreviewVariant.defaultVariant` centraliza `pillActive`. `MainShell` lo usa sin scope experimental y `DevNavigationReview` inicializa su selección con ese mismo valor. Los entrypoints comparten el shell: `main.dart` no necesita editarse. `main_dev.dart` conserva su wrapper de comparación dentro del host D.

La transición de contenido acompaña ahora la barra aprobada en ambos entornos. Conserva el mismo shell hijo, sin clonar Navigators ni introducir rutas o esperas. Cinco destinos: Inicio, Alertas, Vehículo, Historial, Perfil. La operación sigue siendo `shell.goBranch(index, initialLocation: index == shell.currentIndex)`. Estado de ramas, scroll y comportamiento al volver a tocar el destino activo se mantienen.

Los modos Actual y Underline solo se seleccionan en DEV. Una app sin `includeDevRoute` ignora incluso un scope experimental suministrado accidentalmente y muestra Pill Active. Emergencia continúa fuera del shell: no es un sexto destino y retira la barra por el flujo existente.

Indicador/contenido 180 ms `easeOutCubic`; presión 90 ms; feedback Material, foco, labels persistentes, SafeArea y áreas ≥48 dp en los tamaños comprobados. Movimiento reducido completa la transición y elimina desplazamientos/escalas, incluso al cambiar la preferencia durante una animación. No se agregan dependencias o vibración personalizada.

## Checkpoint y validación

Commit local autorizado: `feat(ui): establece Pill Active como navegación predeterminada`.

Incluye la exploración de navegación pendiente desde `36dc291`, su adopción compartida, selector DEV, estilos/componentes, pruebas y documentación. No incluye el análisis posterior de Inicio ni implementación de esa pantalla.

Pruebas dirigidas: `navigation_visual_preview_test.dart`, `motion_pilot_test.dart`, `emergency_flow_test.dart` y `widget_test.dart`. Las aserciones antiguas que inspeccionaban `NavigationBar` se adaptan al componente aprobado y su indicador, sin eliminar los controles de estado/scroll/reducción de movimiento. Análisis estático de los archivos afectados; `git diff --cached --check` y revisión de la lista exacta antes de confirmar. Resultados finales registrados tras completar la validación.

**36 pruebas dirigidas satisfactorias.** Auditoría de ocho archivos exclusiva de navegación, inventario de destinos y contrato `goBranch` conservados; sin patrones de claves/tokens ni artefactos grandes. No se modifica `app_router.dart`, autenticación, Firebase, Providers/repositorios, pantallas funcionales, Login/D, tema global ni dependencias. No se abre Edge, genera capturas o utiliza hardware. Sin push. Esta adopción no aprueba automáticamente otros rediseños ni altera el alcance de un vehículo y un SDA.

## Pendientes

Análisis estático de los seis objetivos afectados: sin incidencias. `git diff --check` satisfactorio. El índice se verifica con la lista explícita de ocho archivos antes del commit.

- Revisión física Android/TalkBack y perfilado de cuadros, teclado externo y configuraciones reales de fuente.
- Biblioteca definitiva de iconos y consolidación de tokens globales mediante AppTheme, sin un sistema paralelo.
- Evaluar posteriores ajustes de densidad, sombra y ergonomía después de la revisión física.
- Inicio: únicamente auditoría funcional/estructural y propuesta documental después del checkpoint. No implementar Inicio ni quitar Vehículo de la barra en esta tarea.
