# Inicio — capacidades y definición de contenido para aprobación

Complemento breve de [FUNCTIONAL_AUDIT.md](FUNCTIONAL_AUDIT.md), 2026-10-17. **Hechos comprobados** en código/documentos frente a **propuestas UX pendientes**. No implementa A/B ni cambia contratos. MAIN significa adaptador Firebase implementado, no comprobación de datos en servicios reales. DEV significa mocks existentes, sin crear escenarios nuevos.

## 1. Matriz de capacidades comprobadas

Abreviaturas: **S** = `SessionProvider.user` (`UserModel?`); **V** = `VehicleProvider.vehicle` (`VehicleModel?`); **D** = `DeviceStatusProvider.status` (`DeviceStatus?`); **E** = `EventProvider`. Las rutas de propiedades de esta tabla son exactas respecto a esas raíces.

| Información / propiedad y modelo | MAIN implementado | Equivalencia DEV / actualización | Ausencia e interpretación pendiente |
| --- | --- | --- | --- |
| Usuario: `S.name`, `S.id` — `UserModel` | `FirebaseAuthRepository` resuelve perfil al cambiar autenticación | `MockAuthRepository`, mismo modelo; ambos notifican por stream de sesión | `S == null`: sin sesión resuelta; el router protege Inicio. Nombre con fallback; no es un stream independiente de cambios de perfil. No mostrar identificadores técnicos. |
| Propietario: `V.ownerId`, comparado con `S.id` — `VehicleModel` | `FirebaseVehicleRepository` valida asociación administrativa y propietario | `MockVehicleRepository` entrega el vehículo semilla; no reproduce las validaciones de autorización | No hay propiedad de rol en `UserModel`. `S.vehicleIds` no reemplaza la resolución del vehículo principal ni acredita permisos. No simular selección de propietario/contacto. |
| Vehículo: `V.brand`, `V.model`, `V.id` — `VehicleModel` | Stream del vehículo principal autorizado, un vehículo | Mismo modelo; mock emite una semilla al suscribirse, sin mutador de vehículo | `V == null` no distingue consulta, falta/invalidez de asociación o error. No certificar «sin vehículo asociado» solo con null. |
| Placa: `V.plate` — `VehicleModel` | Disponible si se resolvió V; campo String validado por tipo | Placa ficticia en la misma propiedad | No hay foto, año, kilometraje, viajes o flota en este modelo. No inventar datos ni inferir categoría/modelo visual exacto de una silueta. |
| Relación SDA–vehículo: `V.deviceId` → `D.deviceId` | `AppProviders` pasa el deviceId resuelto al Provider de estado | Mismo cableado; mock de dispositivo ignora el id solicitado y entrega su semilla | Es asociación administrativa, no prueba física de enlace, instalación correcta ni diagnóstico integral. No exponer el id como información principal. |
| Disponibilidad: `D.online` — `DeviceStatus` | Parser usa `availability.online`, admite `online` de compatibilidad; fallback false | Seed y `setDeviceOffline`; `setSystemOperational` cambia también `state`. Stream con notificaciones | `D == null` ≠ desconectado. Incluso con D, false puede ser fallback si falta el campo; no existe bit de presencia. `online` es enlace, no salud ni garantía de monitoreo. |
| Última comunicación: `D.lastSeen` — `DeviceStatus` | Timestamp RTDB en milisegundos; ausente se convierte en época cero | Seed inicial y cada mutación del mock usan `DateTime.now()` | Es reactivo cuando llega un estado, no un reloj de actualización garantizada. Época cero no es fecha útil. No definir umbral de frescura ni confundir con hora de incidente/fix. |
| Red celular: `D.modem.registered`, `D.modem.operatorName` — `ModemStatus?` | Bloque opcional leído del estado | Seed y `setCellularOffline`, emite cambios | Bloque null = no informado; `registered` ausente dentro del bloque usa false. Es registro celular reportado, distinto de `online` y de disponibilidad satelital. |
| Tecnología: `D.modem.tech` — `ModemStatus` | Texto opcional, no enum cerrado | Misma propiedad; control celular modifica el bloque | null = sin dato. No fijar siempre LTE/4G ni deducir internet a partir del nombre. |
| Señal: `D.modem.rssiDbm` — `ModemStatus` | Entero opcional, dBm | Seed; control celular puede retirar/reponer el valor | Existe `signalQualityLabel`: null desconocida, ≥−85 buena, ≤−105 marginal, resto regular. Puede reutilizarse; no inventar barras/umbrales adicionales ni equiparar señal a salud global. Frescura sigue pendiente. |
| GNSS: `D.gnss.fix`, `fixAgeS`, `satellites`, `hdop` — `GnssPosition?` | Bloque opcional, calidad/edad opcionales | Seed; `setGnssOffline` produce fix false y coordenadas 0,0, no posición conservada | null = bloque ausente; fix false no demuestra que haya una última posición válida. No tratar el 0,0 de la simulación como posición previa real; tampoco usar 0,0 como regla universal de invalidez. |
| Coordenadas: `D.gnss.latitude`, `longitude` — `GnssPosition` | Números requeridos si existe el bloque; sin nombre de lugar | Mismos campos y stream | No hay geocodificación, dirección postal, seguimiento ni cartografía implementados. Un fix reportado no acredita ubicación actual si el SDA está offline o el dato es antiguo. No usar `event.position` como si fuera posición actual del SDA. |
| Batería/alimentación: `D.power.batteryV`, `charging`, `vinOk` — `PowerStatus?` | Bloque opcional; voltios opcionales | Seed equivalente; sin mutador específico de batería en el mock actual | null ≠ batería agotada. `charging` default false y `vinOk` default true no acreditan campos recibidos. No existe porcentaje/autonomía ni regla de batería normal/baja derivada del voltaje. El evento lowBattery es otra fuente/clasificación. |
| microSD: `D.storage.present`, `totalMb`, `freeMb`, `queuedEvents` — `StorageStatus?` | Se parsea `sd`; capacidades opcionales | Seed equivalente; sin mutador específico de almacenamiento | Bloque null ≠ SD ausente. `present` default false y cola default 0 pueden ser fallbacks. Presencia no certifica escritura/salud; no inventar alerta de espacio o cola crítica. |
| Estado/diagnóstico SDA: `D.state`, `firmwareVersion`, `adxl375`, `lsm6ds3`, `pcf8574`, `system` | Modelados y parseados; bloques opcionales y `state` unknown como fallback | Seed; mutadores existentes de estado y sensores | No hay agregación aprobada de «todo correcto». Conservar enum y clasificación; no depender de capturar preAlarm en tiempo real. Detalle secundario para Vehículo. |
| Incidentes: `E.events`, `E.criticalEvent`, `E.error` — `List<AccidentEvent>`, evento y error opcionales | Stream autorizado con consultas acotadas; reconocimiento personal implementado | `MockEventRepository`: stream, disparadores de incidente/técnicos/cancelación y reconocimiento | Fechas/posición/diagnóstico del evento pueden faltar. Clasificación existente `classify` y prioridad `shouldForceCriticalScreen`. No crear política de antigüedad o reinterpretar queued. `event.device.batteryV/rssiDbm/sd` son snapshot del incidente, no telemetría actual. |

**Reactividad y estados comunes:** V y D se actualizan por stream en MAIN y notificación de Provider; sus errores se convierten en null y no exponen `isLoading`/`error`. El mock de V es de emisión única. D y E tienen mutadores DEV, pero no todos los estados de HTML son seleccionables en el simulador. `E.error` sí existe; un error conserva los eventos previos y puede proceder de lectura o reconocimiento, sin categoría pública que los distinga. `E.events == []` es también el valor inicial; no acredita carga terminada ni ausencia definitiva. No hay reintento de UI implementado. Se mantienen las limitaciones descritas en la auditoría anterior.

Fuentes nuevas contrastadas: `lib/models/{user_model,vehicle_model,device_status,modem_status,power_status,storage_status,gnss_position,event_device_snapshot,accident_event}.dart`, `lib/state/app_providers.dart` y repositorios Firebase/mock de autenticación, vehículo, dispositivo y eventos. Se inspeccionó código local, no Firebase real.

## 2. Recuperación de los dos HTML — hechos y valoración UX

El [HTML inicial](../index.html) carga `prototype.js`/`fixtures.js`. El [laboratorio de marca](../brand_system_proposal/index.html) reutiliza esos archivos, aplica `lab.js` y después **`ds-review.js`**: no es solo un cambio de color. El modo refinado agrega Contactos/Historial, modifica marca y contenido y sustituye los escenarios no listos por paneles completos. El modo de paletas conserva composiciones históricas. Ninguna de estas vistas consume los Providers.

| Pieza | HTML inicial / propuesta de marca | Clasificación y recuperación propuesta |
| --- | --- | --- |
| Tarjeta Navy del vehículo | Nombre/placa, silueta vectorial y pie de asociación; marca refina nombre demostrativo y logo | **Reutilizable visualmente**, especialmente en A. Alimentar marca/modelo/placa de V; silueta decorativa, no foto del vehículo ni recorrido. Reducir pie redundante si repite conexión/asociación. |
| Resumen SDA | Separa disponibilidad, última comunicación y métricas; evita promesa de protección | **Reutilizable con simplificación**. Un único resumen de disponibilidad, subordinado a las limitaciones de `online` y fecha. No importar escenarios de carga/antigüedad como estados ya implementados. |
| Métricas batería/señal | Valores fijos de demostración; comparativa «Actual» agrega GNSS y microSD | **Datos demo, propiedades reales opcionales**. La reconstrucción «Actual» no es fiel al grid Flutter vigente: este muestra conexión, red, GNSS y última comunicación. No usar esa columna como evidencia funcional. Llevar diagnóstico detallado a Vehículo; sin batería porcentual ni salud integral. |
| Ubicación | Fila informativa, sin mapa real; inicial tiene botón deshabilitado, refinado solo nota pendiente | **Recuperable y preferible al gran mapa ficticio**. Mostrar coordenadas/calidad disponibles; no ilustrar calles, marcador interactivo o controles de mapa. No añadir «Ver mapa» operativo. |
| Atención y acceso a Alertas | Aviso moderado contextual y enlace a registros | **Reutilizable**: atención antes de contenido secundario; usar evento/clasificación/callback reales, no horas fijas ni acuse local del HTML. |
| Contactos / Historial | No son accesos de contenido en Inicio inicial; refinado los agrega como botones desactivados | **Función pendiente y redundancia parcial**: Historial ya está en el tab; Contactos sigue placeholder. No presentarlos como gestión/consulta terminadas ni como acciones protagonistas. |
| Cinco destinos | Ambos reservan sus lugares, algunos desactivados en HTML | **No trasladar su implementación**. Flutter ya tiene Pill Active y ramas funcionales; conservarlo. |
| Carga/error/vacío/dato anterior | Escenarios controlados manualmente, sin datos reales | **Maquetas dependientes de contratos pendientes**. Recuperar claridad del mensaje, no spinners, temporizadores o diagnósticos ficticios. |

Documentos de apoyo consultados: `../REVIEW.md`, `../brand_system_proposal/{REVIEW,DESIGN_SYSTEM_V1_PROPOSAL,COMPONENTS}.md`. Son propuestas/historial; sus menciones de integración Flutter pendiente no sustituyen el estado actual ya aprobado de Login y navegación.

## 3. Contenido recomendado — propuesta UX para aprobación

**Esencial, con espacio estable aunque falte el dato:** cabecera y saludo discreto; identidad del único vehículo (o mensaje neutral «Información del vehículo no disponible»); disponibilidad reportada del SDA (o «Sin información del SDA»); última comunicación solo con fecha utilizable. No decir «sistema operativo» por tener `online == true`. No afirmar que un null prueba falta de asociación.

**Condicional y prioritario:** banner de atención según clasificación actual, con reconocimiento personal. Los críticos elegibles conservan su ruta fuera del shell. Mostrar error comunicado por E sin exponer excepciones internas y sin atribuirlo automáticamente a lectura; posición ausente/sin fix con mensaje explícito. Estos textos son recomendaciones, no cambios aplicados.

**Ubicación:** una fila de datos recibidos y su calidad, con coordenadas cuando corresponda; sin mapa simulado. No certificar posición actual por `fix == true`, ni última posición válida cuando solo hay coordenadas sin fix. La conservación de última ubicación y la política de frescura requieren la tarea funcional de Fase 5. No añadir dirección/calle, ruta, recálculo, botón de localizar o «en vivo».

**Secundario:** actividad reciente con el límite actual de tres registros, conservando la clasificación y sin llamar a los eventos «viajes»; acceso a Alertas mediante su ruta existente. Batería en V, señal en dBm, almacenamiento y diagnósticos detallados preferentemente en Vehículo cuando esa pantalla se implemente. No convertir métricas presentes en una segunda parrilla protagonista obligatoria.

**Acciones hoy operativas:** cambiar entre ramas existentes, consultar la pantalla Alertas y reconocer el aviso personal. El acceso al detalle existe, pero su contenido es placeholder. Contactos, Historial y Vehículo tienen destinos existentes pero pendientes; preservar sus rutas no implica prometer su función. No simular mapa, gestión de contactos, historial de viajes, reintento, llamada ni comandos al SDA. Antes del diseño debe aprobarse si los accesos secundarios a placeholders se omiten del contenido de Inicio o se mantienen señalados como pendientes; no quitar sus tabs.

| Pantalla | Responsabilidad recomendada |
| --- | --- |
| Inicio | Identificación, disponibilidad reportada, atención contextual, ubicación informativa y actividad resumida. |
| Vehículo | Detalle del único vehículo/asociación y diagnóstico del SDA para propietario; Fase 5 pendiente. Mantener su tab aprobado. |
| Alertas | Registros y acciones existentes por clasificación: atención, informativos, técnicos e historial reciente, sin cambiar reglas. |
| Historial | Archivo futuro de incidentes con consultas acotadas; hoy placeholder. No inventar viajes/estadísticas/exportaciones. |

## 4. Escenarios representables, sin estados nuevos

| Escenario | Presentación posible con el contrato actual | Límite / equivalencia DEV |
| --- | --- | --- |
| Datos disponibles, lista sin incidentes | Vehículo y valores recibidos; «Sin registros para mostrar» en vez de garantía «Todo en orden» | Lista vacía también puede ser inicial; no afirmar consulta completa. Mock E inicia vacío. |
| Incidente de atención | Banner y acuse real; resumen puede permanecer visible | Disparadores DEV existentes; crítico usa su flujo independiente. No cambiar prioridad/clasificación. |
| SDA desconectado | Con D existente, reflejar `online == false`; no asegurar fallo total ni monitoreo detenido | `setDeviceOffline` existe. Red/GNSS previos no se vuelven actuales; no se define vencimiento. |
| GNSS sin fix / desconocido | Con bloque y fix false: «Sin fix GNSS en el dato recibido»; bloque ausente: «Sin datos de ubicación» | Control DEV sin fix existe; genera 0,0. No simular última posición válida; ausencia total no tiene control propio en el mock actual. |
| Sin vehículo asociado | Con V null: mensaje de información no disponible; no afirmar causa ni ofrecer asociación ficticia | MAIN puede emitir null por varias causas; mock V siempre entrega semilla, sin selector de ausencia. No añadir mock en este alcance. |
| Consulta inicial | Antes de resolver, información todavía no disponible | No hay `isLoading` en V/D/E. El spinner/skeleton HTML no tiene señal fiable de fin. No crear duración artificial. |
| Fallo de lectura | V/D null son ambiguos; E.error permite señalar un problema, conservando registros anteriores | E.error no distingue lectura/acuse. No hay controles DEV específicos para todos los fallos ni reintento UI; no fingirlos. |

## 5. Arquitecturas candidatas — misma funcionalidad, distinta jerarquía

| Orden | A — Vehicle Focus | B — Contextual Focus |
| --- | --- | --- |
| 1 | Marca/saludo compacto | Marca/saludo compacto |
| 2 | Aviso de atención cuando exista | Aviso de atención cuando exista |
| 3 | Tarjeta Navy protagonista: vehículo/placa y silueta decorativa | Resumen compacto: disponibilidad SDA y comunicación recibida, con identidad del vehículo siempre explícita |
| 4 | Resumen SDA + última comunicación, sin repetir estados en la tarjeta | Vehículo/placa en superficie secundaria, sin hero ilustrado dominante |
| 5 | Ubicación informativa, sin cartografía | Ubicación informativa y actividad reciente como consulta rápida |
| 6 | Actividad reciente + acceso a Alertas | Acceso a Alertas; mismo límite de actividad que A |
| 7 | Accesos pendientes solo según decisión funcional; Pill Active existente | Exactamente la misma política de accesos; Pill Active existente |

Ambas deben consumir los mismos S/V/D/E, aplicar idénticas condiciones, acciones, clasificación y mensajes de ausencia/error. B no inventa un motor contextual, score de salud ni filtros; A no añade telemetría por su protagonismo visual. El tratamiento de métricas secundarias debe ser equivalente, sin esconder incidentes o cambiar prioridades para favorecer una variante.

**Decisiones que se solicitan para el siguiente incremento:** aprobar este conjunto mínimo; batería/señal/microSD como secundarios para Vehículo; ubicación informativa sin mapa; textos neutrales ante datos ambiguos; política de accesos a placeholders. Esto no aprueba nuevas reglas de frescura, agregación de salud, roles o cambios de Providers. Si se requiere distinguir carga/error/no asociado con precisión, deberá autorizarse primero su contrato funcional separado.

Único cambio de esta tarea: este documento. Sin Flutter, nuevos mocks, navegador, capturas, pruebas automatizadas, dependencias, commit o push. Se conserva la auditoría previa. Se espera aprobación funcional antes de diseñar A/B en Flutter DEV. Para revisar el informe no se requieren SDA, bridge, app/celular, Internet ni Firebase encendidos.

## Aprobación funcional posterior

El usuario aprobó la definición para comparar A/B en Flutter DEV: identificación, atención existente, vehículo, disponibilidad reportada/última comunicación válida, posición informativa, actividad reciente y conectividad secundaria consultable. Tecnología de red y GNSS permanecen temporalmente en Inicio; batería, señal detallada, microSD y diagnósticos se reservan preferentemente para Vehículo. Contactos/Historial adicionales no serán protagonistas; las cinco rutas se conservan. Null no acredita desconexión, inexistencia o fallo; `online` no acredita salud integral. Esta aprobación no define frescura ni amplía los contratos de Providers.

La implementación experimental se documenta en [FLUTTER_REVIEW.md](FLUTTER_REVIEW.md). MAIN conserva Inicio actual; ninguna variante premium queda aprobada como predeterminada por la aprobación funcional.
