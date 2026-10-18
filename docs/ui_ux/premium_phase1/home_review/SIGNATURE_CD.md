# Inicio — Guardian Deck y Signal Flow

**Evolución posterior:** el usuario seleccionó Guardian Deck como base de trabajo, sin aprobar su acabado. Su refinamiento y la comparación de dos ilustraciones dentro del mismo módulo están en [GUARDIAN_REFINEMENT.md](GUARDIAN_REFINEMENT.md). Signal Flow permanece como referencia; MAIN no cambia. Las descripciones C de este documento corresponden al checkpoint `3141a57`.

Propuestas C/D exclusivamente DEV, pendientes de revisión visual humana. No es otra auditoría funcional. Se mantiene el contenido aprobado; Actual, A y B continúan disponibles y MAIN conserva Inicio actual.

## Decisiones artísticas

| | C · Guardian Deck | D · Signal Flow |
| --- | --- | --- |
| Idea | Un módulo de identidad propio: vehículo, enlace reportado y comunicación forman una única pieza Navy. | Una lectura editorial abierta: el enlace reportado funciona como titular, seguido de vehículo y comunicación. |
| Composición | Identidad asimétrica junto a ilustración vial; pie integrado en segundo plano Navy. Esquina inferior diferenciada y sombra única. | Sin gran tarjeta protagonista. Divisor superior Navy, titular de 32 sp y guía vertical Teal para agrupar identidad y comunicación. |
| Gráfica | Ilustración nativa propia de carretera curva y automóvil cenital: carrocería, cristales, ruedas, luces y sombra de contacto. Decorativa; no representa el modelo real ni su ubicación. | La identidad procede de tipografía, alineaciones, jerarquía y ritmo; no se añade una ilustración para llenar espacio. |
| Superficies secundarias | Posición sobre superficie blanca contenida; actividad en filas, sin nuevas tarjetas por evento. | Posición y actividad sobre el mismo plano, separadas por líneas; sin repetir contenedores cerrados. |

Paleta local compartida: Navy `#031B3B`, Aqua `#14E0D3`, Teal `#006D68`, blanco, fondo `#F8F9FA` y texto secundario `#44474D`. En C se usan planos Navy derivados para dar profundidad; Aqua queda limitado a detalles gráficos/borde, sin texto pequeño sobre blanco. Manrope existente: 26–30 sp en saludo, 24 sp en identidad C, 32 sp en titular D, cuerpo 13–17 sp, con escalado del sistema y sin alturas fijas para texto. No se alteran tokens globales.

Al revisar el plan se descartó repetir una tarjeta de conexión debajo del vehículo y se reservó la ilustración para C. D cambia el lenguaje y la agrupación, no solamente la paleta. Los bloques crecen verticalmente con texto grande; C pasa de composición lateral a apilada cuando falta espacio. La ilustración se recorta dentro de su área y no invade el texto.

## Componentes y comportamiento visual

- `HomePreviewVariant` añade C/D. El menú DEV existente enumera las variantes automáticamente: no hay otra pantalla ni selector duplicado.
- `PremiumHomeContent` conserva Providers/callbacks recibidos de `HomeScreen`, el scroll común y las secciones funcionales. `signature_home_directions.dart` es un `part` de presentación local, no otro frontend o sistema de estado.
- `_SdaCopy` centraliza el texto de disponibilidad/última comunicación utilizado por A/B/C/D, con la misma interpretación anterior. No calcula salud ni antigüedad.
- C/D reutilizan posición GNSS, conectividad desplegable, atención y acceso a Alertas. `RecentAlertsPreview.editorial` presenta los mismos eventos mediante filas/divisores; filtro, orden, límite de tres y reconocimiento se conservan. Su default mantiene las referencias anteriores.
- Borde del distintivo de comunicación: 160 ms; ajuste de altura del titular D: 160 ms; expansión de conectividad existente: 180 ms. Movimiento reducido elimina esas duraciones. No se retrasa ninguna acción ni hay animación decorativa periódica. Entrada finita existente, sin nuevas secuencias por sección.
- La gráfica C es `CustomPainter` estático dentro de `RepaintBoundary`, sin animar trazados, blur de escena o cálculos por tick. No se reutiliza ni modifica la geometría de Splash D.

## Validación y límites

`flutter test --no-pub -r expanded test/home_visual_preview_test.dart`: **26/26 satisfactorias**, incluyendo las referencias A/B y nuevas C/D. Comprueba datos disponibles, desconexión y GNSS sin fix desde mocks existentes, atención/reconocimiento, acceso a Alertas y prioridad crítica; ausencia/época cero y error de stream por el contrato real de `EventProvider`. Escenarios de error adicionales solo existen en tests, no en el simulador.

Las cuatro composiciones se comprueban a **320, 360 y 390 × 640 dp, texto 200 % y movimiento reducido**, recorriendo conectividad y acceso a Alertas por teclado. También se conservan la prueba de selección/scroll/ramas y el rechazo de scope experimental en producción. Análisis estático de los cinco archivos Dart del incremento: **sin incidencias**. `git diff --check` satisfactorio. No se repite la batería global de autenticación/Splash.

No hay Edge abierto, capturas, comprobación visual automatizada ni dispositivo físico. La calidad artística, legibilidad percibida, TalkBack y rendimiento Android requieren revisión humana posterior; las pruebas de widget no los certifican. Permanecen los límites del contrato de carga/error/ausencia/frescura ya documentados. No se implementan mapas, viajes, métricas nuevas, contactos o detalle Vehículo.

## Revisar con Hot Reload

Ejecutar `flutter run -t lib/main_dev.dart -d edge` o aplicar Hot Reload a la sesión actual. Si el enum nuevo no se actualiza en una sesión anterior, Hot Restart. Tras el Login mock, abrir el mismo menú de ajustes DEV encima del botón del simulador y elegir **C · Guardian Deck** o **D · Signal Flow**. Actual/A/B siguen en el menú; Pill Active conserva su selector independiente. Usar el simulador existente para desconexión, GNSS offline y atención moderada; SOS comprueba el flujo crítico mock.

Cambios de esta iteración: `home_visual_preview.dart`, `premium_home_content.dart`, nuevo `signature_home_directions.dart`, opción presentacional en `recent_alerts_preview.dart`, pruebas de Inicio y documentación. Los cambios locales previos quedan conservados. Sin cambios de Firebase/repositorios/Providers/router/Login/Splash, dependencias, commits o push. Detenerse para elegir dirección artística; ninguna se promueve a predeterminada y no se inicia Vehículo.

Para esta revisión basta la app DEV local y Edge; SDA, bridge, celular físico y Firebase pueden permanecer apagados. Los mocks no requieren Internet.
