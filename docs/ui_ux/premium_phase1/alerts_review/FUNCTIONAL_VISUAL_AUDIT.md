# Alertas — auditoría funcional y visual previa al rediseño

Base: `b9f4e78`, checkpoint de Inicio Guardian Deck / Editorial Minimal / Lineal. **Solo análisis posterior al commit**: no se modifica Alertas, clasificación, Providers, repositorios, router o acciones. Un vehículo y un SDA, sin flotas.

## Fuentes y capacidades comprobadas

Fuentes: `lib/screens/alerts/alerts_screen.dart`, sus cinco widgets locales, `lib/models/alert_presentation.dart`, `AccidentEvent`, `EventProvider`, `DeviceStatusProvider`, adaptador Firebase de eventos y router. Alcance según `docs/IMPLEMENTATION_PLAN.md` (Fases 2/5/6), `docs/PHASE2_INCIDENT_SPEC.md` y `docs/UI_UX_PHASE1_SPEC.md`. Para la implementación prevalece código/pruebas; el plan conserva tareas funcionales pendientes y no equivale a un despliegue.

`AlertsScreen` observa reactivamente `EventProvider.events` y `DeviceStatusProvider.status`. MAIN recibe los adaptadores Firebase existentes mediante `AppProviders`; DEV usa mocks con el mismo contrato. No hay consultas propias en la pantalla. El repositorio combina fuentes autorizadas y reconocimiento personal, ordena ascendentemente por `ts ?? receivedAt` y mantiene consultas acotadas de 100 filas por rama; no es un archivo ilimitado ni una garantía de lectura completa durante conciliación.

| Grupo existente | Regla / contenido real | Acciones y límites |
| --- | --- | --- |
| Alertas activas | `activeEmergency` y `attention`; tipo, descripción, `detection.peakG` si existe, severidad/SOS, fecha relativa y coordenadas solo con fix | «Ya lo vi» llama al reconocimiento personal; «Ver Detalles» navega a `/incident/:eventId`, cuyo contenido sigue placeholder. Itera en el orden de la fuente, sin invertir ni limitar localmente. |
| Eventos informativos | `informative`: impacto/volcadura leve **o severidad none/unknown** | Tipo/título, descripción, etiqueta Leve, fecha/coordenadas con fix y «Sin acción requerida». Tarjetas no interactivas. |
| Estado técnico | Diagnóstico derivado de `DeviceStatus`: registro celular, fix GNSS, sensores, expansor, microSD y disponibilidad; además eventos test/powerLoss/lowBattery/booted/unknown | Solo lectura. No es un diagnóstico global formal ni solicitud de reparación. Eventos técnicos mantienen su hora relativa; no hay acciones por fila. |
| Historial reciente | `cancelled`, `attended`, `deferred`, invertidos y limitados a cinco | Estado, explicación y hora relativa. No tiene detalle/reapertura/exportación por fila. No sustituye la futura pantalla Historial. |

La cabecera «Actualizado…» utiliza `DeviceStatus.lastSeen`, **no la fecha de actualización de la lista de incidentes**. Los eventos se muestran con `ts ?? receivedAt`; ambos tiempos existen opcionalmente en el modelo, pero la pantalla no los diferencia en etiquetas. La ubicación del incidente pertenece a `event.position`, no a la posición actual del SDA ni del teléfono.

## Clasificación y prioridad que deben preservarse

Precedencia exacta de `classify`:

1. Tipos técnicos/desconocidos → técnico, independientemente de severidad.
2. Evento `cancel` independiente → cancellation, no aparece como fila propia en estos grupos.
3. `cancelledBySeq` → cancelado.
4. `acknowledged` del usuario → visto (`attended` en el enum).
5. `queued` → diferido, aunque sea grave/SOS.
6. SOS o severidad grave → emergencia activa.
7. Moderado → atención no bloqueante.
8. Resto de impactos/volcaduras → informativo, incluyendo severidad no informada.

El router utiliza `shouldForceCriticalScreen` y, tras la protección de autenticación, presenta la emergencia fuera del shell. En uso normal el crítico desplaza la consulta de Alertas; no añadir un sexto tab ni una animación que retrase el redirect. El escape del simulador sigue limitado al evento concreto. No introducir reglas nuevas de antigüedad, transporte, cancelación o prioridad desde presentación.

«Ya lo vi» escribe el estado **del usuario** y espera la actualización de la fuente; no cancela el equipo, resuelve el incidente, solicita ayuda ni reconoce por otros usuarios. `EventProvider.acknowledge` conserva contexto de usuario, registra error y lo relanza si falla. Las tarjetas reciben callbacks `void`, sin estado local de envío, bloqueo de doble toque o feedback de fallo. Resolver esos estados de interacción debe preservar el contrato asíncrono; no simular éxito optimista.

## Estados y problemas comprobados por código

| Hallazgo | Consecuencia / límite para diseñar |
| --- | --- |
| E inicia con lista vacía y no expone `isLoading`; su `error` existe pero Alertas no lo consume. Un fallo conserva registros previos. | Vacío inicial no certifica ausencia de incidentes; no copiar un skeleton con duración artificial ni agregar reintento ficticio. El error no distingue lectura/acuse públicamente. |
| D solo expone estado nullable; su null reúne carga, ausencia y error. | No identificar esas causas desde la UI sin contrato adicional autorizado. |
| Con D null, `TechnicalStatusSection` genera lista de problemas vacía y muestra «Todo funcionando correctamente». También puede afirmar operación de todos los sensores sin que todos sus bloques estén presentes. | Falsa certeza. Documentar un tratamiento neutral para ausencia; no inventar un agregado de salud. Es un ajuste de contenido/interpretación a aprobar, no una corrección aplicada aquí. |
| `modem?.registered != true` y `gnss?.fix != true` tratan bloques ausentes como fallos; el resto de diagnósticos aplica comprobaciones distintas. | Distinguir dato desconocido de negativo reportado requiere revisar el contenido antes de implementar. No extrapolar actualidad desde un snapshot antiguo. |
| Informativos siempre dicen «Leve» y «movimiento o impacto menor», incluso con severidad none/unknown. | La clasificación informativa es correcta según contrato; su texto no debe inventar severidad. Aprobar una etiqueta precisa sin reclasificar eventos. |
| Historial llama `attended` «Incidente atendido» con check verde. | Puede comunicar resolución; proponer «Visto por ti» e icono de visibilidad, coherentes con Inicio. No cambiar el reconocimiento ni la cancelación. |
| «Actualizado» se basa en lastSeen del SDA, con fallback de época cero en el modelo; fecha del evento/recepción se fusiona visualmente. | Etiquetar honestamente qué hora se conoce, sin SLA, TTL o política nueva de frescura. |
| Coordenadas solo con fix y ninguna explicación específica cuando faltan; detalle no implementado. | Recuperar el contexto de ubicación sin mapa ficticio ni promesa de detalle terminado. No trasladar GNSS actual al incidente histórico. |

No hay filtros, búsqueda, paginación visual, borrar avisos, cancelar SDA, llamadas o exportaciones en Alertas. La búsqueda del catálogo HTML no es una capacidad implementada. Acceso de contactos y restricciones técnicas por rol corresponden a la integración pendiente de Fases 3/6; no asumir que esta UI ya implementa otra vista de contacto.

## Recuperación de prototipos HTML

| Fuente | Recuperable visualmente | Representación que no acredita funcionalidad |
| --- | --- | --- |
| `premium_phase1/index.html` + `prototype.js` | «Requieren atención» como primer foco, énfasis ámbar estable, filas/divisores para registros, fecha de evento separada de recepción, explicación del acuse personal | Fixtures, contador fijo de una alerta, carga/error/vacío elegidos manualmente y éxito/fallo de acuse por estado local. No son lecturas RTDB ni operaciones reales. |
| `brand_system_proposal/index.html` + `lab.js`/`ds-review.js` | Marca oficial y jerarquía compartida, agrupación de cuatro secciones, menor peso de superficies, metadatos legibles | Reconstrucción «Actual» no es captura Android ni réplica exacta. Propuesta desactiva botones y sustituye cuerpos con paneles de estados de muestra. No valida carga, búsqueda o interacción real. |

Conservar esas ideas, no copiar plantillas ni fixtures. Incluso los iconos de check del histórico HTML deben revisarse por su posible significado de resolución. Inicio/Nav/Login aprobados no aprueban automáticamente estos prototipos de Alertas.

## Problemas visuales y dirección recomendada — propuestas, no implementación

- Cabecera antigua de escudo genérico, texto y sensores no coincide con la marca oficial de Inicio. Usar una cabecera compacta compartida en identidad, sin repetir el hero del vehículo.
- Muchas tarjetas de radio 24, sombra y borde superior equivalente debilitan la jerarquía entre moderados, informativos y diagnósticos. Reservar superficie protagonista/ámbar a atención; registros en filas con divisores y espacio suficiente.
- El botón elevado de detalles y su color de severidad compiten con el reconocimiento; su destino además es placeholder. Revisar jerarquía visual y alcance del texto sin quitar/cambiar acciones por cuenta propia.
- Titular más metadatos en `Row`, badges laterales, dos botones en una `Row` y fechas finales sin flex son riesgos a 320 dp/texto 200 %. Son riesgos identificados por layout, **no fallos medidos en esta auditoría**. Requerir adaptación, foco visible y objetivos de al menos 48 dp en la implementación; el botón de detalles declara mínimo de 40 dp y debe verificarse su área efectiva.
- El gris de metadatos y estados requiere contraste medido en cada superficie; no asumir accesibilidad por reutilizar un token anterior.
- No hay motion específico de Alertas; hereda la transición de ramas de Pill Active y feedback Material en botones. Añadir únicamente feedback de operaciones reales, sin bucles, cuentas regresivas, swipe ficticio o demora del flujo crítico. Respetar movimiento reducido y montaje retenido.

**Dirección sugerida: «Atención primero, registro claro».** Marca/título discretos → atención moderada existente con sus dos acciones → informativos → técnico distinguido entre dato del SDA y eventos técnicos → cinco históricos con etiquetas precisas. Mantener los cuatro grupos y orden actual de elementos en el primer incremento, sin introducir filtros u ordenaciones nuevas. La alternativa más compacta sería un registro editorial con mayor protagonismo de tipo/estado/tiempo, conservando esos mismos grupos y acciones; no requiere crear otra pantalla o motor de estados.

Reutilizar secciones funcionales, `StatusPill`, helpers de fecha y componentes de marca/actividad cuando exista equivalencia presentacional. Evitar un widget universal que mezcle estado actual del SDA, snapshot de incidente y política de autorización. El siguiente incremento requiere aprobación de composición y textos ambiguos; las ampliaciones de carga/error, mapa, detalle o roles permanecen en tareas funcionales separadas.

## Estado de entrega

Documento creado **después** del checkpoint `b9f4e78`; queda pendiente de versionar, fuera de los 16 archivos de ese commit. No se ejecutan pruebas nuevas por este análisis estático documental; los 63 casos dirigidos de adopción de Inicio quedaron satisfactorios. No se abre Edge ni se generan capturas.

Sin cambios de Alertas u otras pantallas, Firebase, repositorios, router o autenticación; sin push. La revisión humana no requiere SDA, bridge, app/celular, Internet ni Firebase activos. Detenerse aquí para aprobación antes de implementar Alertas.
