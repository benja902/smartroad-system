# Inicio — auditoría funcional y propuesta de estructura

Fecha: 2026-10-17. Base: `85a283c`, checkpoint de Pill Active. Este análisis es posterior al commit de navegación; no implementa el nuevo Inicio ni modifica contratos funcionales. Alcance: un vehículo y un SDA.

## Fuentes y precedencia

- Implementación: `lib/screens/home/home_screen.dart`, sus seis widgets locales, `lib/widgets/attention_banner.dart`, `lib/models/alert_presentation.dart` y `lib/navigation/app_router.dart`.
- Datos: `SessionProvider`, `VehicleProvider`, `DeviceStatusProvider`, `EventProvider`; contratos de repositorios y adaptadores Firebase de vehículo, dispositivo y eventos. DEV utiliza repositorios mock mediante la inyección existente.
- Alcance: `docs/MVP_SCOPE.md`, `docs/IMPLEMENTATION_PLAN.md` (Fases 2, 3, 5 y 6), `docs/PHASE2_INCIDENT_SPEC.md`, `docs/ARCHITECTURE.md` y `docs/UI_UX_PHASE1_SPEC.md`.
- Referencias visuales: Login Signature v2 y navegación Pill Active aprobados. El Design System global sigue pendiente de consolidación; esos acuerdos específicos no aprueban todos sus tokens o componentes.

El código confirma lecturas y acciones ya implementadas; las casillas pendientes del plan no deben interpretarse como funcionalidades completas. Tampoco una clase de repositorio existente implica que su pantalla o integración de roles estén terminadas.

## Qué muestra hoy Inicio

| Bloque | Dato y origen | Comportamiento actual y límite |
| --- | --- | --- |
| Cabecera y saludo | Nombre de `SessionProvider.user`; `DeviceStatusProvider.status.online` | Primer nombre, texto URBES y distintivo de conexión. La frase «Tu sistema URBES está funcionando correctamente» es fija. |
| Estado URBES | `status?.online ?? false` | Se usa el mismo booleano para «operativo/con problemas» y «monitoreo activo/inactivo». No evalúa el estado operativo del firmware ni sus diagnósticos. |
| Atención | Eventos de `EventProvider`, filtrados con `classify == attention` | Muestra el último de la lista filtrada, con reconocimiento personal y acceso al detalle. La clasificación y el orden existentes se conservan. |
| Indicadores | `DeviceStatus`: `online`, `modem.registered/tech`, `gnss.fix`, `lastSeen` | Cuatro indicadores; solo aparecen si hay objeto de estado. Registro celular o fix ausentes se presentan como negativos, sin distinguir desconocido. |
| Vehículo principal | `VehicleProvider.vehicle`: marca, modelo y placa | Resumen del único vehículo y conexión del SDA. Un valor nulo se presenta como «Sin vehículo configurado», aunque también puede deberse a carga o error. |
| Última ubicación | `status.gnss`: coordenadas y `fix` | Dibujo de mapa, no mapa real. Con posición sin fix muestra «última posición conocida»; no evalúa frescura ni disponibilidad del SDA. |
| Acciones rápidas | Rutas existentes | Contactos, Historial y Vehículo. Sus destinos siguen siendo placeholders. |
| Alertas recientes | Misma lista de eventos | Invierte la lista, excluye eventos de cancelación independientes y muestra hasta tres. Incluye eventos técnicos; las filas no tienen acción. Lista vacía muestra «Sin incidentes recientes / Todo en orden». |

La cadena de datos es sesión → vehículo principal → SDA, y sesión/vehículo → eventos. Firebase resuelve el vehículo mediante asociación administrativa y consulta de propietario validada; no selecciona arbitrariamente el primero. El estado se lee de RTDB; `online/lastSeen` proceden de availability. Eventos combina fuentes autorizadas, reconocimiento por usuario y consultas acotadas de 100 filas por rama. No representa una consulta ilimitada del historial completo; el plan documenta además una posible ventana incompleta durante conciliación.

## Estados reales y límites del contrato

| Situación | Qué permite saber hoy el código | Consecuencia para la propuesta |
| --- | --- | --- |
| Conectado / desconectado | `DeviceStatus.online` | Es disponibilidad de comunicación. No certifica por sí sola el funcionamiento integral ni que el SDA haya dejado de monitorear cuando está offline. |
| Operación del SDA | Existe `DeviceOperationalState`: boot, selftest, idle, preAlarm, sending, alertActive, cancelled, safeMode, unknown | Inicio todavía no lo utiliza. No inventar una equivalencia nueva entre esos estados, salud global y severidad. No depender de observar preAlarm en tiempo real. |
| Sin estado | `DeviceStatusProvider.status == null` | Puede ser inicio de consulta, falta de asociación o fallo de stream. El Provider no expone carga ni error diferenciados. |
| Sin vehículo | `VehicleProvider.vehicle == null` | Puede ser consulta pendiente, asociación ausente/inválida o error. No permite afirmar siempre «no configurado». |
| Sin eventos | `EventProvider.events.isEmpty` | También es el valor inicial. No hay señal explícita de carga finalizada; no basta para certificar ausencia de incidentes. |
| Error de eventos | `EventProvider.error` | Está disponible, pero Inicio no lo consume. El Provider conserva eventos previos ante errores; tampoco debe presentarlos como recién actualizados. |
| Dato antiguo / sin fecha | `lastSeen`, fechas del evento y `gnss.fixAgeS` ofrecen información parcial | El modelo usa época cero como fallback de `lastSeen` ausente. La pantalla no debe inventar un umbral de frescura, ni equiparar fecha del evento, recepción y comunicación. La política corresponde a Fase 5. |
| Atención / emergencia | `classify` y `shouldForceCriticalScreen` | Moderados tienen banner no bloqueante; críticos elegibles activan la ruta de emergencia fuera del shell. Cancelado, visto y queued conservan sus reglas. |

Los contratos actuales no permiten representar honestamente todos los estados de carga/error por separado con un simple cambio de layout. Cualquier ampliación de Providers o política de frescura requiere un incremento funcional aprobado, separado del refinamiento visual.

## Acciones: implementación frente a apariencia

| Control | Estado real |
| --- | --- |
| «Ya lo vi» del banner | Acción implementada: reconocimiento individual mediante `EventProvider.acknowledge` y repositorio; no cancela físicamente el SDA ni reconoce por otros usuarios. |
| «Ver detalles» | Navega con la clave del evento, pero el contenido del detalle sigue siendo `IncidentDetailScreenPlaceholder`. |
| «Ver mapa» | Callback vacío en Inicio. El pin y el icono de localización del dibujo no son funciones de mapa implementadas. |
| Contactos / «Gestionar» | Navega a `ContactsScreenPlaceholder`. La implementación local del repositorio de relaciones no convierte este acceso en gestión funcional. |
| Historial / «Ver viajes» | Navega a `HistoryScreenPlaceholder`. No existe aquí un modelo ni historial de viajes; no prometer rutas recorridas, kilometraje o estadísticas. |
| Vehículo / «Detalles» | Navega a `VehicleScreenPlaceholder`. El resumen de Inicio sí consume el vehículo real, pero el destino todavía no es un detalle implementado. |
| Emergencia | Redirect existente del router, fuera de las cinco ramas. Se conserva sin añadir un tab ni esperas decorativas. |

Hallazgo adicional para un incremento posterior: `AttentionBanner` tiene pulso periódico y contador propios, pero no contempla movimiento reducido en su implementación actual. Su callback de reconocimiento es `VoidCallback`: no representa espera/error de la operación asíncrona en el banner. No se corrige en esta auditoría ni se altera la semántica de reconocimiento.

## Propuesta premium para revisión

La pantalla debe responder «qué requiere mi atención y qué sé de mi vehículo», con una jerarquía más clara y menos repeticiones del mismo dato de conexión. Propuesta para la vista de propietario actualmente implementada:

1. **Cabecera compacta:** identidad URBES coherente con Login, saludo de menor protagonismo y sin afirmación global de funcionamiento no verificada.
2. **Atención contextual, cuando exista:** banner por encima del resumen, manteniendo las acciones y clasificación actuales. Emergencia crítica conserva su flujo independiente y prioritario.
3. **Resumen protagonista del único vehículo:** marca/modelo/placa y disponibilidad del SDA claramente identificada. Integrar visualmente los actuales resúmenes de vehículo y conexión, evitando repetir «conectado» en tres tarjetas. Sin selector de vehículos, foto inventada ni controles remotos.
4. **Información de comunicación y posición:** indicadores compactos y ubicación con tratamiento de dato conocido/desconocido compatible con el contrato aprobado. Evitar que un gran mapa ficticio domine la pantalla. La alternativa visual y el tratamiento de la acción no disponible requieren revisión; no implementar un mapa ni un destino nuevo en el rediseño.
5. **Actividad reciente:** conservar el límite actual y la clasificación; no llamar «viajes» a los incidentes. Un acceso a Alertas podría reutilizar la ruta existente, sujeto a aprobación de esta composición. No añadir consultas o filtros nuevos.
6. **Accesos secundarios discretos:** mantener las rutas existentes durante la iteración; decidir cómo señalar los destinos pendientes sin aparentar funciones terminadas. No duplicar los cinco tabs como una segunda barra de navegación.

Lenguaje visual: superficies claras, Navy `#031B3B` para identidad y jerarquía, Aqua `#14E0D3` como acento contenido; colores funcionales acompañados de texto/iconos y reservados a estados sustentados. Tipografía Manrope existente, espacios consistentes, elevación baja y radios compatibles con Signature/Pill. No trasladar automáticamente todos los tokens experimentales al tema global ni repetir el hero animado D en Inicio.

Motion: reutilizar la entrada finita de `ScreenEntrance` (240 ms) y la transición de pestañas ya aprobada (180 ms), sin nuevos bucles decorativos ni reiniciar entradas por cada actualización. Comprobar la suma de ambos movimientos antes de añadir efectos. Proponer cambios concretos de texto/estados para aprobación; esta estructura no define políticas de disponibilidad o frescura.

## Distribución entre pantallas

| Pantalla | Responsabilidad recomendada, sin implementar nuevas funciones |
| --- | --- |
| Inicio | Resumen del único vehículo/SDA, atención no crítica y actividad breve. Información suficiente para orientar, sin todos los diagnósticos. |
| Vehículo | Destino futuro del detalle autorizado: identidad/asociación y estado técnico del SDA para el propietario. Su implementación funcional sigue en Fase 5. |
| Alertas | Consulta de incidentes por su clasificación y eventos técnicos ya separados. Mantener las reglas de reconocimiento/cancelación/diferido y el acceso a detalles. |
| Historial | Futuro archivo de incidentes mediante consultas acotadas; no asumir historial de viajes, filtros o exportaciones no aprobadas. |
| Emergencia | Experiencia crítica independiente y prioritaria, nunca dentro de la barra inferior. |

**Recomendación: conservar Vehículo en la navegación actual.** Es un módulo del alcance MVP y forma parte de los cinco destinos que el usuario acaba de aprobar. El hecho de que hoy sea un placeholder no justifica eliminar su rama durante un cambio visual. Un único vehículo permite simplificar su contenido, pero no elimina la utilidad de consultar el detalle técnico sin saturar Inicio.

Más adelante podría convertirse en detalle accesible desde el resumen si la validación demuestra uso poco frecuente o duplicación de contenido. Ese cambio requiere aprobación explícita de arquitectura de información, acceso/back, estado de ramas y nuevas pruebas; no se deriva de esta auditoría. Comparar cuando exista contenido funcional de Vehículo, no solamente su placeholder.

El contacto autorizado tiene otro alcance en las Fases 3/6: emergencias autorizadas sin administración ni diagnósticos técnicos por defecto. No aplicar esta vista de propietario a contactos ni fingir un selector de roles; su autorización/integración funcional aún debe completarse.

## Reutilización y siguiente incremento propuesto

- Evolucionar `VehicleSummaryCard` y `UrbesStatusCard` como una composición local de Inicio; extraer un componente compartido solo si hay consumidores equivalentes reales.
- Reutilizar `StatusPill`, `SectionHeader`, `AttentionBanner`, `RecentAlertsPreview`, `DeviceIndicatorsGrid` y `QuickActionsRow` cuando corresponda, conservando sus contratos y diferenciando las mejoras funcionales pendientes.
- Mantener `ScreenEntrance`, SafeArea, scroll, ancho máximo y la navegación compartida aprobada. Evolucionar `AppTheme` cuando se autorice consolidar el Design System; no crear un tema paralelo para Inicio.
- Primer incremento sugerido: composición visual de Inicio en Flutter DEV, conservando la referencia actual, sin nuevas lecturas, rutas o acciones. Antes de implementarlo, aprobar la jerarquía, la reducción de duplicaciones y el tratamiento de textos/controles pendientes.
- Separar después la tarea funcional de Fase 5: estados inequívocos de carga/error, frescura y geolocalización. No simular esos estados con temporizadores o datos inventados.

Validación futura dirigida: escenarios mock de conexión, ausencia de vehículo/estado, eventos de atención y críticos, reconocimiento y error; conservación de scroll y ramas; fuentes grandes, pantalla estrecha, teclado/foco, semántica, contraste y movimiento reducido. Dispositivo Android físico y perfilado solo con autorización puntual. No se ejecutan pruebas adicionales por esta auditoría documental.

## Estado de entrega

Checkpoint de navegación `85a283c`: ocho archivos, 36 pruebas dirigidas satisfactorias, análisis estático sin incidencias. Sin cambios de rutas, autenticación, Firebase, repositorios, Login ni Splash D; sin push.

Esta auditoría queda como documento posterior pendiente en el árbol de trabajo, fuera del commit de navegación. No se ha implementado Inicio ni decidido políticas funcionales nuevas. La siguiente intervención requiere aprobación humana de la propuesta; no hace falta encender SDA, bridge, app/celular ni servicios Firebase para revisar este documento. No se han utilizado hardware ni servicios reales.
