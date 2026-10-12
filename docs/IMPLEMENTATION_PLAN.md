# Plan de implementación de SmartRoad

Este plan ordena el trabajo por dependencias. Cada casilla representa una tarea que puede ejecutarse y validarse de forma individual con Codex. Solo se marcan como completadas las actividades comprobadas documentalmente; no se declara implementada ninguna funcionalidad nueva.

El orden de las fases expresa la secuencia principal, pero los checkpoints físicos tempranos pueden ejecutarse en paralelo con el trabajo conceptual y local. Del mismo modo, el backend de RockBLOCK puede comenzar una vez completadas las fases 1–2, aunque su integración final con FCM y Flutter dependa de fases posteriores.

**Principio global:** preservar y evolucionar el flujo funcional existente. No reemplazar componentes que ya funcionan salvo que una necesidad explícita del MVP lo requiera. Preferir cambios incrementales sobre reescrituras.

**Alcance congelado del MVP:** se mantienen íntegros el alcance aprobado en `MVP_SCOPE.md` y las Fases 0–10 de este plan, incluidos contactos autorizados, FCM, contingencia RockBLOCK/Iridium, despliegue cloud, APK y validación física. El MVP es un **prototipo experimental**, no un servicio de respuesta a emergencias ni una garantía de entrega o atención. Los defectos que comprometen detección, ingesta, autorización, notificación o presentación del flujo principal se corrigen en las fases existentes con el cambio mínimo verificable, sin crear subsistemas adicionales.

**Separación y trabajo diferido:** la identidad y los datos del incidente, la cancelación física del SDA y el reconocimiento individual por usuario siguen siendo conceptos independientes. El cierre administrativo del seguimiento familiar, su reapertura y el historial de esas acciones, así como una política integral de antigüedad de 48 horas, quedan diferidos y no bloquean el MVP. Esto no impide corregir en las Fases 2 y 5 que una alerta crítica antigua vuelva a interrumpir al usuario. El portal institucional de entidades de rescate y su seguimiento de intervenciones permanecen como ampliaciones futuras. No crear ahora nodos, campos, servicios ni abstracciones para estas funciones diferidas o futuras.

## Fase 0 — Línea base y documentación

- [x] Auditar estáticamente el repositorio, la aplicación Flutter, el bridge y la documentación existente.
- [x] Contrastar el contrato técnico con `manual-sda (4).html`.
- [x] Definir las reglas permanentes de trabajo en `AGENTS.md`.
- [x] Aprobar y documentar el alcance del MVP.
- [x] Consolidar el contrato de integración del SDA.
- [x] Documentar la arquitectura objetivo de software.
- [x] Crear este plan por dependencias.
- [x] Adoptar Google Cloud como plataforma de alojamiento del backend, manteniendo Firebase Authentication, RTDB y FCM.
- [x] Separar conceptualmente el consumidor MQTT persistente del webhook HTTP de Iridium/Ground Control.
- [x] Incorporar `manual-sda (4).html` como referencia versionada vigente y clasificar los manuales anteriores como históricos.
- [x] Mantener `main_dev.dart`, los mocks y el simulador como entorno DEV reproducible.
- [x] Mantener `main.dart` y los repositorios Firebase reales como entrada de producción.
- [x] No incorporar flavors ni un ambiente staging por ahora; reconsiderarlos únicamente si la integración lo exige.

## Checkpoints físicos tempranos — integración

Estos checkpoints validan supuestos de alto riesgo, pero no bloquean el desarrollo conceptual y local de las fases 1–2 ni sustituyen las pruebas de aceptación de la fase 10.

- [ ] Confirmar el `deviceId` real del prototipo final.
- [ ] Confirmar el IMEI del RockBLOCK.
- [ ] Comprobar físicamente que `seq` persiste después de apagar o reiniciar el SDA.
- [ ] Capturar y anonimizar al menos un payload MQTT real emitido por el firmware final.

Los valores reales no deben incorporarse a documentación, fixtures ni código. La provisión administrativa mínima de Fase 1 quedó cerrada con las confirmaciones disponibles; los checkpoints formales siguen pendientes y deberán completarse antes de cerrar la integración RockBLOCK y las pruebas end-to-end.

La identidad del SDA se confirmó con una prueba física y eventos reales para seleccionar **la asociación administrativa del MVP**; el IMEI se confirmó privadamente para registrar el único RockBLOCK. Esa evidencia permitió la provisión de Fase 1, pero no se archivó como verificación formal reproducible de todos los checkpoints: las casillas anteriores permanecen abiertas hasta registrar evidencia anonimizada y completar las comprobaciones de persistencia de `seq` y payload final. No volver a provisionar ni alterar relaciones ya validadas solo por estas casillas.

## Fase 1 — Modelo de datos, provisión y seguridad

- [x] Definir el catálogo de identificadores requeridos, su autoridad, sensibilidad, ciclo de vida y participación en autorización o deduplicación.
- [x] Definir el modelo conceptual de usuarios y relaciones por vehículo sin diseñar todavía pantallas.
- [x] Definir la asociación propietario–vehículo–dispositivo.
- [x] Definir la asociación de contactos autorizados y su alcance.
- [x] Definir la representación mínima de incidente, destinatarios y estado de atención.
- [x] Diseñar los nodos y claves de RTDB para lecturas autorizadas e idempotencia.
- [x] Implementar la compatibilidad MVP definida en `RTDB_COMPATIBILITY_MVP.md`: lectura dual de `ts`, transición aditiva `userId` → `vehicleId`, estado individual por usuario y preservación de cancelaciones. Validada y cerrada el 3 de octubre de 2026; evidencia del Bloque 4 en el documento de compatibilidad.
- [x] Implementar una provisión administrativa mínima para el propietario, vehículo, SDA, IMEI y contactos del MVP. Asociación y RockBLOCK aplicados y validados; primer contacto real provisionado con perfil y relación `pending`. El límite de hasta tres contactos está probado localmente, sin crear cuentas innecesarias. La cuenta del contacto permanece inhabilitada hasta implementar las reglas y el acceso por rol.
- [x] Tras validar la provisión, impedir la creación automática de dispositivos demo en producción, conservando el modo DEV y sin eliminar datos existentes en el mismo cambio. Validado manualmente en `main.dart` el 3 de octubre de 2026: el propietario cargó su vehículo, SDA y eventos existentes; tras cerrar sesión y volver a entrar no aparecieron nuevos datos demo.
- [x] Tratar el inicio de sesión de una cuenta Firebase Auth sin perfil `users/{uid}` en RTDB: se cierra esa sesión, se evita construir un usuario provisional y el acceso manual muestra un mensaje específico; un perfil existente sin vehículo sigue admitido. Pruebas automáticas aprobadas y flujo del propietario real validado manualmente en `main.dart` el 3 de octubre de 2026.
- [x] Garantizar que `main.dart` use Firebase real y que `main_dev.dart` permanezca aislado con mocks y simulador. Entradas y composición verificadas; el propietario ya validó `main.dart` y una prueba directa de `main_dev.dart` confirmó los cuatro mocks y la ruta DEV sin inicializar Firebase.
- [x] Escribir reglas de RTDB acordes con roles, asociaciones y escrituras exclusivas del backend. Publicadas el 4 de octubre de 2026 tras comparar las reglas desplegadas con las locales; la lectura posterior confirmó coincidencia exacta. `RTDB_RULES_PHASE1.md` documenta el alcance y la validación.
- [x] Crear pruebas locales específicas para las reglas de RTDB. **30 pruebas aprobadas en Emulator** para propietario, contactos, consultas, denegaciones y escrituras exclusivas del backend.
- [x] Antes de publicar las reglas, provisionar y verificar por campo `users/{ownerUid}/ownerVehicleId` para el propietario real, comparar las reglas desplegadas con las locales y validar `main.dart` después de una publicación autorizada. Campo aplicado y comprobado por lectura; dry-run posterior sin cambios. El usuario probó `main.dart` como propietario después de publicar y no reportó anomalías. La cuenta del contacto permanece inhabilitada.
- [x] Realizar una limpieza controlada de los datos demo que interfieran con producción. Tras retirar el segundo registro de `devices`, la verificación de solo lectura del 4 de octubre de 2026 confirmó que permanece únicamente el SDA real, asociado al vehículo y al registro administrativo activos; se conservaron los 2 usuarios y los 33 eventos del inventario previo, sin referencias huérfanas en `userIncidentState`. El IMEI, el contacto `pending` con su cuenta inhabilitada y las reglas publicadas permanecieron coherentes. El usuario comprobó después `main.dart` como propietario y reportó que todo funciona correctamente.

## Fase 2 — Robustez y modelo canónico de incidentes

**Bloque 2.1 — modelo canónico y contrato de ingesta MQTT.** La especificación de entrada es [`PHASE2_INCIDENT_SPEC.md`](PHASE2_INCIDENT_SPEC.md). Cerrado en su alcance local de software tras aprobar 2.1a–2.1d; no incluye webhook real, FCM, pantallas nuevas, firmware, infraestructura cloud ni migración destructiva. Los demás renglones de Fase 2 siguen tareas independientes.

**Estado SDD:** 2.1a (validador MQTT puro) aprobado tras revisión independiente `APROBABLE` y 26/26 pruebas locales del bridge. 2.1b (ingesta y persistencia MQTT compatible) aprobado tras revisión independiente `APROBABLE`: 44/44 pruebas del bridge y 31/31 de reglas RTDB con Emulator. 2.1c (cancelaciones y recuperación) aprobado tras corrección de C05 y revisión independiente `APROBABLE`: 56/56 pruebas del bridge con Database Emulator. 2.1d (lectura Flutter e históricos) aprobado tras revisión independiente `APROBABLE`: 61/61 pruebas Flutter dirigidas, 7/7 de flujo de emergencia/widgets y análisis estático de los seis archivos afectados sin problemas. **Bloque 2.1 cerrado en software local**; no equivale a despliegue, validación física ni cierre de toda la Fase 2.

**Aceptación verificable del Bloque 2.1:** pruebas locales con datos ficticios demuestran los escenarios aplicables de la matriz de la especificación: evento válido, duplicado/retransmisión, payload inválido y discrepancia de identidad, tiempos diferenciados sin sobrescribir la primera recepción, actualización sin perder cancelación ni reconocimiento, `queued`, asociación ausente y colisión de `seq` según la política aprobada. Conservar lectura de eventos históricos y el comportamiento DEV; ninguna prueba depende de Firebase real, SDA o satélite. Registrar explícitamente qué escenarios de fusión Iridium permanecen pendientes de la implementación del webhook. No marcar ningún ítem funcional como hecho por documentación o por pruebas propuestas solamente.

**Consultas acotadas del propietario — incremento aprobado y cerrado en software local.** El índice cronológico y las consultas separadas de críticos antiguos tienen pruebas de bridge, reglas RTDB y Flutter; la recuperación programada del índice fallido quedó comprobada sin reiniciar el bridge (64/64 pruebas del bridge con Emulator, 34/34 de reglas y 67/67 Flutter dirigidas). Se mantienen los límites de 100 filas por rama, la posible ventana incompleta hasta terminar la conciliación y la validación pendiente con servicios reales. La lectura de contactos sigue en Fase 3.

**Identidad MQTT y límites de entrada — incremento aprobado y cerrado en software local.** El bridge comprueba la coincidencia `id`–topic y la estructura antes de persistir, rechaza comodines MQTT en el identificador y aplica un límite defensivo de 64 KiB antes de analizar el JSON. La autenticidad del dispositivo emisor continúa pendiente de comprobar con las ACL y credenciales de HiveMQ real; el límite de procesamiento no se atribuye al firmware.

- [ ] Definir el modelo canónico que recibirán Flutter, MQTT y RockBLOCK.
- [ ] Separar tiempo del dispositivo, tiempo de recepción y tiempo de actualización.
- [ ] Representar explícitamente `queued`, fuente de transporte y calidad de datos.
- [x] Definir reglas de fusión para incidentes parciales y enriquecimiento posterior. Política MQTT aprobada y comprobada en 2.1b; la convergencia Iridium↔MQTT sigue en Fase 7.
- [x] Soportar cancelaciones que lleguen antes o después del evento original. Comprobado en 2.1c con duplicados, concurrencia y recuperación local.
- [x] Definir el tratamiento de `ts` ausente, inválido o igual a cero. Comprobado para MQTT y lectura Flutter en 2.1; la unidad numérica real del firmware sigue pendiente de verificación física.
- [x] Definir la política ante reutilización inesperada de `seq`. Las colisiones incompatibles se rechazan sin sobrescribir; la persistencia real de `seq` tras reinicio sigue pendiente del checkpoint físico.
- [ ] Validar que el `deviceId` del payload corresponda al topic autenticado. Coincidencia declarada `id`–topic comprobada localmente; falta verificar la autorización de publicación por dispositivo en HiveMQ real.
- [x] Validar tipos, severidades, tamaños y rangos antes de persistir. Validador MQTT y límite defensivo de 64 KiB comprobados localmente; no equivalen a una garantía sobre el tamaño emitido por el firmware.
- [x] Hacer idempotente la ingesta MQTT por `(deviceId, seq)`. Comprobado con duplicados, enriquecimiento compatible y concurrencia en 2.1b–2.1c.
- [ ] Preservar cancelaciones, acuses y notificaciones durante actualizaciones.
- [x] Implementar consultas acotadas para historiales y alertas, suficientes para el MVP del propietario. Índice cronológico local por propietario con ventanas de 100 incidentes y consultas separadas para críticos activos antiguos; autorización comprobada con Emulator. La lectura de contactos corresponde a Fase 3, cuya proyección aún no tiene productor operativo. Pendiente despliegue y validación con servicios reales.
- [ ] Crear pruebas del bridge para duplicados, reconexión, orden invertido y payloads inválidos.
- [ ] Mantener o ampliar escenarios reproducibles del simulador DEV para clasificación, incidentes, cancelaciones, `queued`, GNSS inválido, offline y duplicados.

## Fase 3 — Roles y contactos de emergencia

- [ ] Implementar la resolución de las relaciones autorizadas del usuario autenticado con cada vehículo.
- [ ] Implementar lectura del vehículo y SDA asignados al propietario.
- [ ] Implementar la incorporación mínima de contactos mediante un flujo seguro y auditable.
- [ ] Implementar aceptación o revocación de autorización.
- [ ] Restringir al contacto a incidentes autorizados y críticos.
- [ ] Impedir que el contacto administre vehículo, SDA o eventos técnicos.
- [ ] Añadir pruebas de autorización positiva y negativa por rol.
- [ ] Conectar roles y contactos a repositorios de producción sin eliminar ni mezclar los mocks del modo DEV.

## Fase 4 — Notificaciones FCM

- [ ] Registrar y renovar tokens FCM por usuario y dispositivo móvil.
- [ ] Desasociar o eliminar del backend los tokens al cerrar sesión y limpiar tokens inválidos u obsoletos cuando Firebase los reporte.
- [ ] Solicitar permisos de notificación según la versión de Android.
- [ ] Configurar el canal Android para emergencias críticas.
- [ ] Emitir una sola notificación por la primera recepción válida del incidente.
- [ ] Resolver destinatarios según rol, autorización, tipo y severidad.
- [ ] Manejar notificaciones con la app en primer plano, segundo plano y cerrada.
- [ ] Abrir el detalle correcto mediante deep link o datos de notificación.
- [ ] Evitar una segunda notificación cuando MQTT enriquezca un evento recibido por Iridium.
- [ ] Probar registro y renovación de token, limpieza al cerrar sesión y entrega real al propietario y a un contacto.

## Fase 5 — Módulos del propietario

- [ ] Conectar Inicio con estado real del vehículo, SDA y emergencia activa.
- [ ] Implementar Alertas con los estados y filtros esenciales del MVP.
- [ ] Implementar detalle de incidente y su evolución.
- [ ] Implementar mapa y geolocalización con indicación de calidad.
- [ ] Ajuste pendiente por hallazgo físico (validación en fase 10): conservar la última posición y etiquetarla como "última ubicación conocida" cuando el SDA esté offline; no presentar LTE/GNSS antiguos como disponibilidad actual y usar timestamps/frescura para distinguir estado actual de último dato conocido. No implementado todavía.
- [ ] Implementar Vehículo con información autorizada del único prototipo.
- [ ] Implementar Historial mediante consultas acotadas suficientes para el MVP.
- [ ] Implementar Perfil y cierre de sesión.
- [ ] Implementar gestión de contactos de emergencia.
- [ ] Mostrar eventos técnicos, batería baja y conexión principalmente al propietario.
- [ ] Retirar datos temporales y mocks únicamente de las rutas de producción, conservando `main_dev.dart` y el simulador reproducible.

## Fase 6 — Módulos del contacto de emergencia

- [ ] Implementar Inicio limitado a emergencias autorizadas.
- [ ] Implementar Alertas críticas.
- [ ] Implementar Historial crítico mediante consultas acotadas suficientes para el MVP.
- [ ] Implementar detalle y mapa sin controles del vehículo o SDA.
- [ ] Implementar Perfil y cierre de sesión.
- [ ] Verificar que eventos técnicos, batería y conexión no se expongan indebidamente.
- [ ] Probar revocación de acceso y pérdida de asociación.

## Fase 7 — Integración RockBLOCK / Ground Control

El bloque backend puede comenzar después de completar las fases 1–2, en paralelo con las fases 3–6. La integración final con destinatarios FCM y pantallas Flutter requiere que roles, notificaciones y módulos móviles estén disponibles.

### Backend independiente

- [ ] Obtener y versionar la especificación vigente del webhook HTTP y JWT de Ground Control.
- [ ] Implementar el registro seguro IMEI–`deviceId`.
- [ ] Crear el endpoint cloud de recepción.
- [ ] Validar autenticidad y autorización antes de procesar.
- [ ] Deduplicar por `(imei, momsn)`.
- [ ] Decodificar el payload binario de 39 bytes.
- [ ] Validar longitud, `magic`, versión y CRC.
- [ ] Verificar el hash FNV-1a del `deviceId`.
- [ ] Convertir el mensaje a un incidente canónico parcial.
- [ ] Converger por `(deviceId, seq)` y enriquecer con MQTT posterior.
- [ ] Conservar la ubicación CEP como alternativa diferenciada del GNSS.
- [ ] Confirmar la recepción HTTP dentro del límite de tres segundos.
- [ ] Crear fixtures y pruebas para payloads válidos, corruptos y duplicados.

### Integración posterior con FCM y Flutter

- [ ] Exponer el origen satelital y la ubicación CEP mediante el modelo y los repositorios autorizados.
- [ ] Integrar los incidentes recibidos por Iridium con la resolución de destinatarios y FCM.
- [ ] Verificar en Flutter el enriquecimiento MQTT posterior sin duplicar incidentes ni notificaciones.

## Fase 8 — Despliegue cloud

- [ ] Elegir y documentar los servicios concretos y la topología de Google Cloud.
- [ ] Diseñar el despliegue independiente del consumidor MQTT persistente.
- [ ] Diseñar el despliegue independiente del webhook HTTP de Ground Control.
- [ ] Fijar instalación reproducible desde el lockfile con `npm ci`.
- [ ] Configurar secretos como variables administradas, sin incluirlos en el repositorio.
- [ ] Configurar conexión MQTT TLS y sesión persistente.
- [ ] Proteger públicamente el webhook con el mecanismo validado de Ground Control.
- [ ] Añadir logs mínimos de operación y error sin datos sensibles.
- [ ] Verificar reconexión a MQTT, reanudación de sesión y consumo del backlog.
- [ ] Definir health checks y política de reinicio.
- [ ] Desplegar ambos componentes backend en Google Cloud sin dependencia de una PC local.
- [ ] Ejecutar una prueba de humo contra Firebase y el broker reales.

## Fase 9 — APK release

- [ ] Verificar configuración FlutterFire para el proyecto y ambiente correctos.
- [ ] Revisar permisos Android mínimos necesarios.
- [ ] Confirmar identificador, nombre, iconos y versión de la aplicación.
- [ ] Configurar firma release y custodiar las credenciales fuera del repositorio.
- [ ] Ejecutar análisis y tests completos en un árbol sin dependencias generadas dentro del alcance del analizador.
- [ ] Generar el APK release reproducible.
- [ ] Instalar y probar el APK para propietario y contacto.
- [ ] Documentar la instalación básica y la versión del APK entregado.

## Fase 10 — Pruebas físicas end-to-end

Esta fase repite los supuestos comprobados en los checkpoints tempranos dentro del sistema final desplegado. Los checkpoints no sustituyen esta validación completa de aceptación.

### Hallazgos de validación física — pendientes de medición y ajuste

Observaciones registradas el 3 de octubre de 2026; no implican cambios de código ni una causa técnica confirmada:

- Al apagar el SDA, la transición a offline tarda aproximadamente un minuto. No atribuir todavía este tiempo a latencia MQTT.
- Cuando el SDA queda offline, Flutter continúa mostrando LTE/GNSS y posición con los últimos valores recibidos.

- [ ] Medir por etapas el tiempo desde el apagado hasta la visualización de offline: apagado del SDA, detección/publicación de offline en el broker, recepción en el bridge, actualización de RTDB y recepción/visualización en Flutter. Registrar tiempos y evidencias para identificar dónde se produce la demora, sin presuponer su causa.
- [ ] Validar el ajuste pendiente de la fase 5: conservar la última posición como "última ubicación conocida", no mostrar LTE/GNSS antiguos como disponibilidad actual y distinguir estado actual de último dato conocido mediante timestamps/frescura.

### Pruebas de aceptación

- [ ] Verificar conexión, Last Will, disponibilidad y estado retained del SDA.
- [ ] Generar eventos físicos controlados de cada tipo permitido.
- [ ] Verificar tipo, severidad, métricas y geolocalización extremo a extremo.
- [ ] Verificar cancelación y llegada en orden invertido.
- [ ] Verificar cola sin conectividad y transmisión posterior con `queued`.
- [ ] Verificar el último recurso SMS conforme al manual.
- [ ] Verificar FCM con la app abierta, minimizada y cerrada.
- [ ] Verificar visibilidad diferenciada para propietario y contacto.
- [ ] Reiniciar el backend y comprobar recuperación sin duplicados.
- [ ] Ejecutar el diagnóstico RockBLOCK sin depender de USB.
- [ ] Ejecutar una prueba satelital pagada solo con aprobación previa.
- [ ] Verificar Iridium primero y MQTT después sin duplicar incidente ni notificación.
- [ ] Apagar la PC de desarrollo y confirmar el flujo completo mediante infraestructura cloud.
- [ ] Registrar evidencias, tiempos, IDs anonimizados y resultados de aceptación.

## Evolución futura — tareas diferibles

Estas tareas pueden aportar valor a una evolución comercial, pero no bloquean la entrega ni la aceptación del MVP con un único prototipo SDA:

- [ ] Generalizar la provisión administrativa para múltiples usuarios, vehículos y dispositivos.
- [ ] Crear migraciones reutilizables y versionadas para estructuras históricas o despliegues con datos no descartables.
- [ ] Definir políticas avanzadas de auditoría y retención.
- [ ] Implementar paginación genérica o sofisticada para historiales y alertas.
- [ ] Añadir filtros avanzados, búsquedas y un historial técnico detallado.
- [ ] Incorporar preferencias de notificación por contacto, administración avanzada de múltiples teléfonos y analítica de entrega.
- [ ] Generalizar la fusión de incidentes para transportes o proveedores adicionales.
- [ ] Implementar observabilidad completa con métricas, dashboards y alertas operativas.
- [ ] Añadir alta disponibilidad multirregión, autoescalado avanzado e infraestructura como código completa.
- [ ] Incorporar ambientes staging o flavors si la integración futura los requiere.
- [ ] Ampliar las pruebas a una matriz extensa de dispositivos Android y escenarios prolongados de carga.
- [ ] Diseñar actualización, reinstalación, rollback y distribución empresarial entre múltiples versiones.
- [ ] Preparar publicación en Google Play Store.
- [ ] Generalizar el producto para multiempresa, multiflota o nuevos roles organizacionales.
