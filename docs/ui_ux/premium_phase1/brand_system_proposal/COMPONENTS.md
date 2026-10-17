> Actualización del 16 de octubre de 2026: propuesta DS v1.0 pendiente. Los seis incrementos Splash→Login están aprobados DEV; la tabla se actualiza abajo para distinguirlo del diseño global aún provisional.

# Componentes y mapa de reutilización — propuesta

15 de octubre de 2026. Inventario basado en código; las variantes descritas son candidatas. No declara componentes nuevos implementados ni Design System v1.0 aprobado.

## Inventario diferencial

| Pieza | Estado comprobado | Evolución propuesta / responsabilidad |
|---|---|---|
| `AppTheme`, `ThemeData`, `AppColors`, `AppTypography`, espaciado/radios/sombras | Existentes en `lib/core/theme/`; tema global Material 3. | Una sola fuente Flutter futura: roles aprobados a `ColorScheme`/`TextTheme` y temas de controles; roles de incidentes explícitos. Nada de un segundo paquete de tokens. |
| `PrimaryButton` | Existente; Login lo utiliza y toma estilo del tema. | Normal, pulsado, foco, envío y deshabilitado. La operación y su disponibilidad pertenecen al controlador existente. No reconstruir autenticación para añadir un spinner. |
| `GhostButton` | Existente como widget compartido disponible. | Acción secundaria cuando haya operación real; no forzar su uso en las cuatro pantallas. Revisar consumidores antes de cambiar API. |
| `CriticalButton` | Existente; Emergencia lo utiliza con color explícito/default. | Contraste de texto/fondo y estados; separar acuse personal de severidad. Cambiar la jerarquía de su CTA exige aprobación de diseño; no reinterpretar su función. |
| `TextFormField` + `InputDecorationTheme` | Login los utiliza; no hay biblioteca propia de campos. | Etiqueta persistente, ayuda/error, foco, texto grande, teclado/autofill. Mejorar tema y composición local; no crear `AuthField` genérico por tener dos campos. |
| `StatusPill` | Existente; Inicio, Alertas y Emergencia. Una propiedad `color` alimenta texto y fondo al 15 %. | Separar visualmente acento, texto y superficie por roles. Estados desconocido/antiguo/diferido solo si el contrato los identifica. Texto/icono redundante y `wrapLabel` cuando corresponde. |
| `SectionHeader` | Existente; Inicio y secciones de Alertas. | Escala y spacing compartidos; no convertir todo título en este widget ni duplicar la urgencia de Emergencia. |
| `ScreenEntrance` / `EntranceSection` | Existentes; Login e Inicio; 240 ms, control finito y reducción de movimiento. | Reutilizar donde ya cumplen; coordinar visibilidad con intro DEV. No añadir entrada global a Emergencia ni reiniciar por datos/teclado. |
| `AttentionBanner` | Existente en Inicio; pulso/temporizador previos. | Propuesta de énfasis estático y acciones existentes. Eliminar pulso Flutter necesita autorización posterior, no se cambia aquí. |
| `AlertCard` y secciones de Alertas | Código existente dentro del módulo. | Revisar consumidores, densidad, divisores y jerarquía; permanecer locales mientras solo sirvan a Alertas. No extraer una superclase universal de tarjetas. |
| `VehicleSummaryCard`, `UrbesStatusCard`, `DeviceIndicatorsGrid`, `QuickActionsRow`, `RecentAlertsPreview` | Existentes y específicos de Inicio. | Evolucionar presentación con datos aprobados. Disponibilidad de dispositivo no se convierte en garantía del sistema. Mantener clases locales y feedback Material. |
| `LocationMapPlaceholder` | Existente en Inicio. | No convertir el placeholder en mapa funcional ni añadir navegación/reintento inexistente. |
| `NavigationBar` / shell | Existente, compartido por ramas Inicio y Alertas. | Tema/selección accesible; cinco destinos y `goBranch` intactos. No aparece en Login ni Emergencia. |
| Marca SVG / futuro `BrandMark` | Recurso SVG suministrado disponible; widget Flutter con nueva marca aún no existe. | Nueva pieza de presentación pequeña justificable por varios consumidores. Selección de variante oficial por fondo y tamaño; sin recolorear el original ni añadir runtime por anticipado. |
| Futuro resumen visual de ubicación/tiempos | Hoy hay presentaciones específicas de cada pantalla. | Extraer únicamente si dos consumidores comparten la presentación. Recibir etiquetas, calidad y valores ya resueltos; no calcular frescura, posición actual o prioridades de transportes en el widget. |
| Futuro estado visual de contenido | Prototipos maquetan carga/vacío/error; proveedores no tienen necesariamente todos esos estados. | Solo proponer una pieza compartida cuando existan contratos y dos consumidores. No inventar operaciones de reintento ni modelos de backend dentro del rediseño. |
| Escena ilustrada Splash/Login | SVG y motion de revisión existentes; integración Flutter nueva pendiente. | Presentación aislada DEV cuando se autorice. La escena no es la base de todas las pantallas; no crear un shell animado permanente. |

## Mapa entre las cuatro pantallas

**E:** uso existente comprobado (directo o por tema/shell). **P:** reutilización futura propuesta, no implementada. **—:** sin necesidad actual; no se fuerza un consumidor.

| Pieza | Login | Inicio | Alertas | Emergencia |
|---|:---:|:---:|:---:|:---:|
| Tema, tipografía, spacing, roles | E | E | E | E |
| Nueva marca / `BrandMark` | P | P | P | P opcional, subordinada a urgencia |
| `PrimaryButton` | E | — | P si una acción ordinaria lo requiere | — |
| `CriticalButton` | — | — | — | E |
| Controles Material por tema | E | E | E | E |
| `StatusPill` | — | E | E | E |
| `SectionHeader` | — | E | E | — |
| `ScreenEntrance` | E | E | — | — |
| `NavigationBar` del shell | — | E | E | — |
| Jerarquía visual de incidente, tiempo y calidad | — | P en resumen | P sobre módulos existentes | P sobre composición existente |
| Resumen presentacional ubicación/tiempo | — | P condicionado | P si hay consumidor equivalente | P condicionado |
| Estado carga/error/vacío compartido | — (envío propio) | P condicionado al proveedor | P condicionado al proveedor | — (no bloquear incidente) |
| Ilustración isométrica | P en cabecera | — | — | — |

El mapa distingue reutilización visual de equivalencia de datos. Un estado del SDA en Inicio y una ubicación del incidente en Emergencia no son el mismo dato por verse parecidos. La presentación no decide permisos, clasificación ni actualidad.

## Integración Flutter futura

1. Aprobar pares y roles con estas muestras y variantes de componentes; mantener un único conjunto de tokens en los archivos actuales.
2. Evolucionar un control/consumidor por incremento. Estilos Material comunes en `AppTheme`; geometría exclusiva dentro del widget que la necesita.
3. Mantener `Provider` como estado y repositorios como acceso a datos. Los componentes reciben valores/callbacks aprobados; no importan Firebase ni crean consultas.
4. Mantener `GoRouter` y redirección crítica. Los componentes no navegan ni demoran una acción para terminar motion.
5. Limitar reconstrucciones al estado que cambia; contenido estable mediante `child`/`const` cuando corresponda. Animar transformación/opacidad pequeña o pintura, sin recomputar geometría estática ni clasificar incidentes por cada tick.
6. Verificar accesibilidad y pruebas dirigidas del incremento antes de propagarlo. Perfilado UI/raster en dispositivo solo con autorización; no justificar refactors de rendimiento sin evidencia.

Los nombres nuevos son candidatos. No se crean wrappers de cada `Padding`, `Text` o `Container`, ni motores de formularios, temas por pantalla o widgets que absorban política funcional.

## Auditoría consolidada de componentes v1.0

| Componente / responsabilidad | Existencia y estrategia | Estados / límites |
|---|---|---|
| `LoginScreen` / `LoginFormParts` | Reutilizar el formulario único y presentación opcional del Incremento 6. | Reposo/foco/ocupado/error/autofill ya funcionales; iconos y ojo propuestos, no implementados. No extraer otro formulario. |
| `PrimaryButton` | Existente; evolucionar tema ElevatedButton. | Normal/pulsado/foco/ocupado/deshabilitado. Altura mínima 56; texto escalable. |
| `GhostButton` | Existente basado en TextButton; reutilizar para acción secundaria por contexto. | Foco legible; no inventar una clase SecondaryButton solo para cambiar color. OutlinedButtonTheme sirve al caso con borde. |
| `CriticalButton` | Existente, color contextual explícito. | Proponer tonos de acción accesibles `#B52F34` y `#80520A`; no convertir acuse ordinario en llamada urgente. |
| Correo/contraseña | TextFormField del Login, personalización por `InputDecorationTheme`. | Iconos 20, hit area del ojo 48, etiqueta/error asociados; conservar validadores. |
| Búsqueda | No hay componente de búsqueda compartido en las cuatro pantallas auditadas. | Muestra de catálogo; no crear widget ni capacidad hasta existir consumidor/operación aprobados. |
| `StatusPill` | Existente, recibe un color único y deriva alpha 15 %. Evolucionar hacia pares explícitos cuando se autorice. | Normal/desconocido/atención/crítico; texto accesible, icono opcional y wrap. |
| `SectionHeader` | Existente; reutilizar en secciones reales. | No botones vacíos ni truncado de acciones. |
| `AttentionBanner` | Existente con pulso/temporizador. Proponer énfasis estable. | Conservar acuse/detalle actuales; quitar pulso requiere implementación posterior autorizada. |
| Tarjetas locales de Inicio | `VehicleSummaryCard`, `UrbesStatusCard`, `DeviceIndicatorsGrid`, `QuickActionsRow`, `RecentAlertsPreview`. | Evolucionar cada consumidor; sin Card universal ni inferir estado a partir de decoración. |
| Tarjeta y secciones Alertas | `AlertCard`, `ActiveAlertsSection`, `InformativeEventsSection`, `TechnicalStatusSection`, `RecentHistorySection`. | Clasificación, tiempos, `queued` y acuse intactos. |
| Barra de navegación | NavigationBar del shell, cinco ramas. | Normal/seleccionado/foco; reutilizar tema, no crear navegación paralela. |
| Diálogos/confirmaciones | Flutter Material en operaciones específicas existentes (por ejemplo contactos); no componente global necesario aún. | Tema compartido antes que wrapper; una muestra de catálogo no añade confirmación al acuse. |
| Carga/vacío/error | Presentaciones locales y `ComingSoonView`; no contrato global uniforme demostrado. | Empty no equivale a éxito; unknown no equivale a offline. Extraer ContentState solo con dos consumidores y contratos reales. |
| `PremiumClosureArtboard` / Login preview | DEV existente y aprobado; un solo lockup y escena. | No tocar D ni crear otro host. No activarlo en main.dart. |

`BrandMark`, un resumen de tiempo/ubicación y ContentState siguen siendo nombres propuestos, no componentes ya implementados globalmente. Revisar consumidores antes de extraer. El orden de evolución está en [la propuesta consolidada](DESIGN_SYSTEM_V1_PROPOSAL.md#plan-flutter-posterior-no-autorizado-todavía).
