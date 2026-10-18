# Inicio — adopción compartida aprobada

El usuario aprobó oficialmente **Guardian Deck + A · Editorial Minimal + A · Ilustración lineal**, dentro de Silent Guardian — Signature y con Pill Active. Esta combinación es la presentación inicial de Inicio en MAIN y DEV. No supone despliegue, aprobación de todo el Design System ni cambios de dominio.

## Configuración e invariantes

Los valores `defaultVariant` de `HomePreviewVariant`, `GuardianHeader` y `GuardianArtwork` centralizan la combinación. `HomeScreen` la utiliza fuera de DEV, ignorando cualquier scope experimental. `DevNavigationReview` inicia con los mismos valores y conserva Actual/A/B/Signal Flow, Signature Header e ilustración 2.5D para comparar; no hay dos HomeScreen ni Providers nuevos.

Ambos entrypoints ya utilizan el mismo `UrbesApp`/router/HomeScreen: no necesitan ediciones en `main.dart` o `main_dev.dart`. MAIN conserva la inyección Firebase/RTDB de `AppProviders`; DEV conserva los repositorios mock. No se ejecutan servicios reales para validar este cambio de presentación.

Se mantienen suscripciones reactivas, valores/semántica de disponibilidad, última comunicación válida, red móvil, GNSS, posición, datos técnicos opcionales y actividad. `classify`, `shouldForceCriticalScreen`, reconocimiento personal, prioridad moderada/crítica y operación de ramas no cambian. Pill Active sigue predeterminada. Login Signature v2 y autorización de Splash D permanecen como estaban; no se activa D automáticamente en producción.

## Checkpoint

Mensaje autorizado: `feat(ui): establece Guardian Deck como Inicio predeterminado`.

Incluye refinamiento de cabeceras/conectividad/actividad pendiente, selección compartida aprobada, sus pruebas, documentación y dos renders propios de esa revisión previa. No genera capturas nuevas. Los renders de Signature/2.5D son alternativas históricas, no evidencia de que esa combinación sea la predeterminada aprobada.

Auditoría previa: pendientes exclusivamente de esta etapa de Inicio, sin conflictos ni cambios preparados ajenos. Recursos nuevos pequeños: pintor de cabecera, documento y dos PNG de mocks. Sin dependencias nuevas, APK, build/cachés, referencias externas o archivos de configuración sensibles. No se mueve ni elimina geometría o recursos existentes; los componentes siguen en sus rutas y el nuevo `part` se incluye explícitamente.

La documentación previa conserva el proceso exploratorio. Este documento prevalece sobre sus indicaciones históricas de MAIN con Inicio actual o aprobación visual pendiente. La elección visual no resuelve carga/error ambiguos, frescura o funcionalidades placeholder.

## Validación y siguiente etapa

Pruebas dirigidas de Inicio, navegación/arranque real DEV, emergencia y widget básico; análisis estático de diez archivos afectados. Producción se prueba con el árbol compartido `UrbesApp(includeDevRoute: false)` y repositorios de prueba, sin inicializar Firebase; además se revisa que `main.dart` sigue conectándolo a los adaptadores reales. La prueba adversarial suministra Signal Flow/Signature/2.5D y comprueba que producción muestra Guardian/Editorial/Lineal sin selector DEV.

Antes del commit: lista explícita de archivos, revisión de diff, comprobación de recursos y `git diff --cached --check`. No se abre Edge, generan nuevas capturas o usa hardware. Sin push. La siguiente etapa es exclusivamente análisis de Alertas después del checkpoint; no implementar esa pantalla.

**Resultado:** 63 pruebas dirigidas satisfactorias (34 Inicio, 22 navegación, 6 emergencia y 1 arranque básico). En la primera pasada pasaron 62; el test básico conservaba la búsqueda de marca como texto. Se adaptó a su etiqueta accesible dentro del grupo semántico y se liberó el handle antes de terminar; su repetición aislada pasó. No hubo correcciones funcionales derivadas de la validación. Análisis estático de diez archivos de implementación/pruebas y del test básico adicional: sin incidencias. La prueba de arranque real `main_dev.dart` comprueba la combinación Guardian/Editorial/Lineal tras el Login mock y la navegación existente.
