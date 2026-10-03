# Compatibilidad MVP entre la implementación actual y RTDB

## Propósito

Esta tarea prepara una transición incremental desde el flujo actualmente funcional `MQTT → bridge → RTDB → Flutter` hacia el modelo descrito en `RTDB_MODEL.md`. No autoriza una reescritura, una migración destructiva ni la eliminación inmediata de campos o datos existentes.

La compatibilidad previa a la provisión se considera implementada cuando los consumidores actuales continúen funcionando y se hayan validado los cuatro primeros frentes. El quinto frente, retiro del bootstrap, permanece como tarea separada y solo puede cerrarse después de validar la provisión. Este documento registra el alcance y la evidencia de cada bloque; no sustituye las pruebas pendientes.

## Estado de cierre — 3 de octubre de 2026

**Compatibilidad MVP completada**, tras la validación y aceptación del usuario. Se cierra únicamente la tarea de compatibilidad de la Fase 1: lectura tolerante de `ts`, transición aditiva y consulta dual, reconocimiento individual y preservación de cancelaciones. La evidencia local y real se detalla en cada bloque.

La validación real final del Bloque 4 ejecutó una sola secuencia **SOS → cancelación → retransmisión con la misma identidad y `ts` diferente**. Se conservaron exactamente `cancelledBySeq` y `cancelledAt`, el estado individual y los 24 eventos previos. RTDB terminó con 26 registros: un único SOS nuevo y su registro de cancelación. No se ejecutó Flutter para esta prueba, no se alteraron reglas ni hubo escrituras administrativas directas; los dos registros de prueba permanecen en la instancia.

Este cierre no completa la provisión administrativa, el retiro del bootstrap demo, las reglas finales de roles ni la limpieza de datos. Tampoco certifica los checkpoints físicos, la política temporal de la Fase 2 o la integración RockBLOCK. El análisis de la provisión puede comenzar; su implementación y aplicación real requieren un bloque posterior autorizado.

## 1. Compatibilidad de `ts`

### Estado actual comprobado

- En la inspección de 21 eventos reales, 17 almacenaban `ts` como cadena y 4 no lo incluían.
- `receivedAt` está almacenado como timestamp numérico del backend.
- El modelo Dart ya acepta `ts` como cadena ISO 8601 o número y usa `receivedAt` como respaldo cuando `ts` es ausente o inválido.

### Transición MVP

- Flutter debe aceptar temporalmente `ts` como cadena ISO 8601 o como timestamp numérico.
- Un `ts` ausente o inválido no debe impedir leer el incidente; para presentación y orden se usa `receivedAt` como respaldo.
- La política específica para `ts == 0` queda en la Fase 2. El parser actual acepta el cero numérico como época Unix; este cierre no declara implementado un fallback especial para ese valor.
- La lectura compatible no debe reescribir automáticamente los eventos históricos.
- El formato canónico de escritura y la confiabilidad del tiempo del SDA se cerrarán en la Fase 2.

Consumidores que justifican esta compatibilidad: Flutter presenta y ordena incidentes; el bridge y Firebase conservan el valor reportado por el firmware.

## 2. Transición de `userId` a `vehicleId`

### Estado actual comprobado

- El bridge resuelve la asociación del SDA y escribe `userId` y, cuando está disponible, `vehicleId` en los nuevos eventos.
- Flutter combina las consultas de `events` por `userId` y `vehicleId` cuando se conoce el vehículo; sin `vehicleId`, conserva la consulta anterior.
- En la inspección de RTDB real del 30 de septiembre de 2026, 12 eventos solo tenían `userId` y 9 tenían ambos campos.

### Transición MVP

1. El bridge debe resolver la asociación activa `deviceId → vehicleId` y añadir `vehicleId` sin retirar inicialmente `userId`.
2. Flutter debe poder leer los eventos nuevos por `vehicleId` y mantener un fallback temporal para los eventos históricos que solo tengan `userId`.
3. Las reglas e índices posteriores deben basar la autorización en relaciones por vehículo, nunca en el conocimiento de `userId`, `deviceId` o una clave de evento.
4. `userId` solo podrá retirarse cuando ningún repositorio, consulta ni dato histórico necesario dependa de él.

Consumidores: el bridge produce `vehicleId`; Firebase lo indexa; Flutter lo usa para consultas autorizadas; FCM lo usará para resolver destinatarios.

### Validación y cierre del Bloque 2 — 30 de septiembre de 2026

- Las pruebas locales dirigidas del repositorio Firebase y el mock terminaron con **12 pruebas aprobadas**. Cubrieron la unión de las dos fuentes, un evento recuperable únicamente por `vehicleId`, deduplicación por `eventKey`, orden por `ts` con respaldo en `receivedAt`, preservación de cancelaciones y cancelación de suscripciones.
- Se compararon las reglas RTDB desplegadas con `database.rules.json`; eran idénticas antes del cambio. Se añadió y publicó únicamente `vehicleId` en `.indexOn` de `events`, conservando `userId`, `deviceId`, `seq` y todas las reglas de autorización. Una lectura posterior confirmó el cambio exacto.
- En RTDB real, la consulta por `userId` devolvió 21 eventos y la consulta por `vehicleId` devolvió 9. Los 9 estaban también en la primera consulta: la unión por `eventKey` produjo **21 eventos únicos**, incluidos 12 históricos sin `vehicleId`. Las copias superpuestas no presentaron diferencias de campos. Se conservaron 6 incidentes con cancelación y 4 registros requirieron `receivedAt` para el orden.
- El usuario validó manualmente `main.dart` y reportó **21 eventos finales y 21 `eventKey` únicos** después del merge. Este resultado complementa la inspección administrativa; la instrumentación temporal usada para observarlo no forma parte del alcance permanente del bloque.
- Los datos reales actuales no contienen un evento que aparezca exclusivamente por `vehicleId`; ese caso está cubierto por pruebas locales y podrá comprobarse en Firebase cuando exista un evento de ese tipo. No se crearon datos para forzar el escenario.

Bloque 2 cerrado para el flujo y los datos disponibles. En ese momento, la tarea global permanecía abierta por el estado individual del usuario y la preservación de cancelaciones en escritura; el cierre posterior se registra al inicio de este documento.

## 3. Estado individual del usuario

### Estado actual comprobado

El `acknowledged` global existente se conserva como respaldo histórico. Tras cerrar el Paso 4B, los nuevos reconocimientos se almacenan únicamente en el estado individual y no alteran el evento global ni el estado de otros usuarios.

### Representación mínima MVP

```text
userIncidentState/{uid}/{eventKey}
  acknowledged: true
```

- `acknowledged` es consumido por Flutter para dejar de presentar el incidente como pendiente para ese usuario.
- No cancela el incidente, no cambia su estado global y no modifica el estado de otros usuarios.
- Flutter solo podrá escribir su propio estado cuando las reglas correspondientes hayan sido implementadas y probadas.
- Durante la transición, Flutter puede leer primero el estado individual y usar el `acknowledged` global existente como fallback para eventos históricos del propietario.
- Las nuevas confirmaciones deben escribirse únicamente en el estado individual una vez habilitada la nueva ruta.
- No se añaden todavía preferencias, analítica de lectura ni estados de entrega FCM.

### Paso 3 — reglas mínimas validadas localmente, sin publicar

Validación realizada el **2 de octubre de 2026**: **18 pruebas aprobadas, 0 fallos** en Firebase Database Emulator con el proyecto ficticio `demo-smartroad-rules` y datos exclusivamente locales.

La adición local en `database.rules.json` permite leer únicamente `userIncidentState/{auth.uid}`. Cada escritura exige que el evento exista y que se cumpla una de las alternativas compatibles: `events/{eventKey}/userId == auth.uid` o `vehicles/{events/{eventKey}/vehicleId}/ownerId == auth.uid`. Solo admite `acknowledged` booleano; rechaza campos adicionales, borrados y escrituras al estado ajeno. No incorpora autorización de contactos.

Las pruebas verificaron autorización histórica y por vehículo, denegaciones, escrituras multipath, preservación de cancelaciones y permisos e índices actuales de `events` sin cambios. La configuración local se encuentra en `firebase.emulator.json`; las dependencias, el lockfile, los casos y las instrucciones reproducibles están en `test/rtdb_rules/`.

No se publicaron reglas ni se modificaron datos reales. La lectura personal sigue desactivada por defecto y la escritura global de “Ya lo vi” sigue vigente. La publicación y la activación requieren un bloque posterior autorizado. Estas reglas mínimas no sustituyen las reglas finales de asociaciones y roles: los permisos previos de escritura de `vehicles` también permanecen pendientes de endurecimiento.

### Paso 4A — publicación de reglas mínimas, sin activar Flutter

El **2 de octubre de 2026**, tras autorización explícita del usuario, se publicaron únicamente las reglas de `userIncidentState` en la instancia RTDB utilizada por Flutter. La comparación previa confirmó que todas las demás reglas desplegadas coincidían con las locales y que la nueva ruta todavía no estaba definida.

La publicación respondió **HTTP 200**. Una lectura posterior confirmó coincidencia exacta con las reglas candidatas y preservación íntegra de las demás reglas, incluidos permisos e índices de `events`. No se escribieron datos de usuarios, vehículos, dispositivos, eventos ni estados individuales.

La validación de permisos con usuarios simulados sigue respaldada por las **18 pruebas del Emulator** del Paso 3; la lectura administrativa posterior verifica el despliegue, no sustituye esas pruebas. No hace falta ejecutar `main_dev.dart`, `main.dart`, el bridge ni hardware para comprobar esta publicación. La lectura personal permanece desactivada y “Ya lo vi” conserva la escritura global hasta implementar y validar el Paso 4B.

### Paso 4B — reconocimiento individual activado y validado en Firebase real

El **2 de octubre de 2026** se activó por defecto la lectura personal en los repositorios Firebase y mock. “Ya lo vi” captura el `uid` de la sesión a través de `EventProvider` y escribe únicamente `userIncidentState/{uid}/{eventKey}/acknowledged = true`. También se conectó a ese proveedor la acción equivalente del panel DEV. El evento canónico, el campo global almacenado, las cancelaciones y la clave `{deviceId}_{seq}` no se modifican.

La lectura conserva el fallback global solo para eventos históricos **sin `vehicleId` cuyo `userId` coincida con el usuario actual**. En eventos con `vehicleId`, sin reconocimiento personal, la confirmación global no se hereda: pueden volver a mostrarse como pendientes si solo estaban atendidos globalmente. No se migran ni se copian confirmaciones automáticamente.

Las **65 pruebas dirigidas pasaron** y el análisis Dart de los archivos afectados terminó **sin problemas**. Cubrieron la ruta exacta de escritura Firebase mediante un doble local, errores sin escritura global alternativa, falta de sesión, captura del usuario ante cambios de sesión, estado independiente entre usuarios, fallback histórico, cancelaciones, merge, orden, clasificación y regresiones de emergencia/DEV. Los errores de lectura quedan registrados en `EventProvider.error`; los errores de escritura se propagan y no se convierten en una confirmación local. No se añadió una nueva presentación de errores en las pantallas.

Comando ejecutado desde la raíz del proyecto, en primer plano:

```powershell
flutter test --no-pub -r expanded test/firebase_event_repository_acknowledge_test.dart test/event_provider_user_state_test.dart test/firebase_event_repository_user_state_test.dart test/mock_event_repository_user_state_test.dart test/mock_event_repository_test.dart test/firebase_event_repository_merge_test.dart test/accident_event_test.dart test/alert_classification_test.dart test/emergency_flow_test.dart test/dev_simulator_test.dart
```

Las pruebas automáticas no requieren celular, bridge, Firebase real ni SDA. Las pruebas manuales de la app requieren un dispositivo Android o emulador:

1. **DEV (`flutter run -t lib/main_dev.dart`)**: generar choque grave, volcadura grave o SOS; pulsar “Ya lo vi”; comprobar que se cierre la emergencia y se muestre como atendida. Generar otro incidente y comprobar que siga abriendo la emergencia. En otro incidente, usar la cancelación del simulador y verificar que se presente como cancelado. No hacen falta internet, bridge ni SDA. El estado mock se conserva dentro de la ejecución, no después de cerrar completamente y reiniciar la app.
2. **Firebase (`flutter run -t lib/main.dart`)**: usar la cuenta propietaria existente y un incidente ya almacenado. Observar el `acknowledged` global antes de pulsar “Ya lo vi”; después comprobar en la consola, sin editar datos manualmente, que aparezca el estado propio en `userIncidentState` y que el evento global permanezca intacto. Cerrar y volver a abrir la app o iniciar nuevamente la misma sesión; el incidente debe seguir atendido para ese usuario. Hace falta conexión a Firebase; no hacen falta bridge ni SDA si ya existe el incidente.
3. **Históricos y cancelaciones**: comprobar que los históricos sin `vehicleId` siguen disponibles, que el fallback global del propietario se conserva y que los cancelados siguen cancelados. La independencia entre dos usuarios se valida localmente mediante tests; no requiere crear cuentas ni asociaciones nuevas en Firebase.

La implementación y las pruebas automáticas no escribieron estados individuales reales. Posteriormente, el **2 de octubre de 2026**, el usuario reportó la siguiente validación manual en Firebase real mediante `main.dart`:

- Se generó un incidente nuevo que, antes de reconocerlo, no tenía `acknowledged` global.
- “Ya lo vi” creó únicamente `userIncidentState/{uid}/{eventKey}/acknowledged = true`.
- `events/{eventKey}` permaneció intacto.
- Después de cerrar y volver a abrir `main.dart`, el incidente continuó reconocido y no reapareció como pendiente.

Esta evidencia, junto con las pruebas locales, **cierra el Paso 4B y el Bloque 3 de estado individual**. Se registra como validación manual reportada por el usuario, sin incorporar identificadores reales ni atribuir una inspección adicional a Codex. En ese momento, la tarea global permanecía abierta por la preservación de cancelaciones en la escritura del bridge, cerrada posteriormente en el Bloque 4.

## 4. Preservación de cancelaciones

- `cancelledBySeq`, `cancelledAt` y el futuro estado global `cancelled` pertenecen al incidente y no al usuario.
- Una retransmisión, un enriquecimiento o un `ts` diferente no pueden borrar ni revertir una cancelación ya aplicada.
- La actualización del incidente debe fusionar campos; no debe enviar valores nulos que eliminen evidencia previa de cancelación.
- Si el `cancel` llega primero, debe conservarse la evidencia necesaria para completar después el mismo incidente nominal.
- Los registros `cancel` independientes ya existentes se conservan durante la transición. Flutter puede excluirlos de las listas de incidentes, pero no deben eliminarse hasta validar la reconciliación canónica de la Fase 2.

Consumidores: el bridge aplica y preserva la cancelación; Firebase conserva el estado global; Flutter deja de presentar el incidente como activo; FCM no debe volver a notificarlo como una emergencia nueva.

### Bloque 4 — pasos 1 y 2: implementación y pruebas locales

El **2 de octubre de 2026** se retiró de la escritura del bridge el borrado de `acknowledged`, `cancelledBySeq` y `cancelledAt` basado en diferencias de `ts`. También se descartan esos campos del payload MQTT antes de fusionar. La política ante reutilización real de `seq` sigue pendiente de la Fase 2.

La escritura se aisló en `bridge/event_writer.js`, que es invocado por `index.js` con las mismas dependencias de producción. Se conservan la clave nominal, la asociación administrativa, la actualización de `receivedAt`, los registros `cancel` independientes y la proyección de cancelación sobre el incidente original. El Dockerfile incluye el nuevo módulo sin realizar un despliegue.

Las **12 pruebas locales de Node pasaron, 0 fallos**. Cubrieron ambos órdenes de llegada para `crash`, `rollover` y `sos`, retransmisiones con `ts` cambiado, ausente o nulo, reconocimiento global histórico, descarte de estados recibidos por MQTT, asociación ausente y ausencia de escrituras en `userIncidentState`. Se ejecutaron en primer plano mediante `npm --prefix bridge test`, con progreso `spec` y un doble de base de datos en memoria. Las comprobaciones de sintaxis de `index.js`, `event_writer.js` y del archivo de tests también pasaron.

No se cargó `.env`, no se arrancó MQTT, no se accedió a Firebase real y no se modificaron datos existentes durante estas pruebas. No hacen falta celular, SDA, bridge activo ni Flutter para repetirlas. El comando y su alcance están documentados en `bridge/README.md`.

Al finalizar los pasos 1 y 2 quedaba pendiente la comprobación con el bridge activo y una fuente MQTT de prueba. Las pruebas locales por sí solas no cerraban la validación real; su resultado posterior se registra debajo.

### Bloque 4 — paso 3: comprobación previa del 2 de octubre

El **2 de octubre de 2026** se identificó un proceso local del bridge iniciado antes de la última actualización de `index.js` y `event_writer.js`. Es necesario reiniciarlo antes de enviar mensajes para que la prueba valide la versión actual. La sonda local del puerto 8080 tampoco permitió confirmar la conexión al broker. No se publicaron mensajes MQTT ni se modificaron datos o reglas de Firebase durante esta comprobación.

El escenario propuesto es una publicación controlada por MQTT con las dependencias ya disponibles: SOS sintético, `cancel` con su propio `seq` y `cancels_seq` apuntando al SOS, y retransmisión del mismo SOS con idéntico `deviceId` y `seq`. Se usará QoS 1, sin retained, una asociación existente y claves previamente comprobadas como libres; no habrá escrituras administrativas directas en RTDB. Se comprobarán las lecturas después de cada envío, la conservación exacta de `cancelledBySeq` y `cancelledAt`, el estado personal sin cambios y la ausencia de un segundo incidente. La observación visual en `main.dart`, si se realiza, se registrará por separado de la verificación de datos.

En esa comprobación no se declaró realizada ni aprobada la validación real: quedaba pendiente reiniciar y confirmar el bridge actualizado antes de ejecutar una sola secuencia de prueba.

### Bloque 4 — paso 3: validación real aprobada el 3 de octubre de 2026

Tras la confirmación del usuario, se verificó que el proceso local del bridge había arrancado después de la actualización de `index.js` y `event_writer.js`. Las lecturas autenticadas confirmaron una única asociación utilizable y **24 eventos** existentes. Se verificó también que la RTDB consultada correspondía a la configuración de Flutter. Los identificadores y las credenciales se procesaron localmente sin incorporarlos a esta documentación ni mostrarlos en la salida.

Se ejecutó **una sola secuencia** en primer plano mediante la dependencia MQTT existente, con cliente de prueba independiente, TLS, QoS 1 y sin retained: **SOS sintético → cancelación → retransmisión del SOS**. Antes de publicar se comprobaron como libres las dos claves de prueba. La cancelación tuvo su propio `seq` y apuntó al SOS mediante `cancels_seq`. La retransmisión conservó `deviceId` y `seq`, cambiando únicamente `ts` en un segundo para comprobar específicamente el riesgo anterior de borrado por diferencia de tiempo.

Las lecturas posteriores a cada envío confirmaron:

- El SOS nuevo se persistió en su clave nominal con `userId` y `vehicleId` provenientes de la asociación existente y sin `acknowledged` global.
- La cancelación proyectó `cancelledBySeq` y `cancelledAt` sobre el incidente original.
- Tras la retransmisión, ambos campos conservaron **exactamente** los valores posteriores a la cancelación; el nuevo `ts` quedó persistido, confirmando que la retransmisión fue procesada.
- La identidad y la asociación del incidente permanecieron iguales. Existió **un solo incidente** con ese `deviceId` y `seq`.
- La comparación completa de `userIncidentState` antes y después no encontró cambios. Tampoco cambiaron los 24 eventos preexistentes.
- RTDB terminó con **26 registros**: se añadieron únicamente el SOS sintético y su registro `cancel` independiente. No se creó un segundo incidente.
- El incidente conserva la evidencia que el clasificador actual de Flutter interpreta como `cancelled`, no como emergencia activa. Esto es una verificación de datos y del criterio existente, **no una observación visual de la aplicación**.

La ejecución terminó correctamente, con **0 escrituras administrativas directas en RTDB**. Todas las escrituras de eventos fueron realizadas por el bridge al consumir MQTT. No se modificaron código, reglas, Flutter, firmware ni datos manualmente; no se ejecutó Flutter ni se utilizó hardware físico. Los dos registros de prueba se conservaron, sin limpieza posterior.

Este resultado cierra el **Paso 3 y la validación de preservación de cancelaciones del Bloque 4** para el escenario autorizado. No valida colisiones reales de `seq`, integración física ni escenarios adicionales de la Fase 2. Tras la aceptación explícita del usuario, la tarea global de compatibilidad se marca como completada el 3 de octubre de 2026. La provisión administrativa todavía no se implementa ni se aplica sobre Firebase.

## 5. Retiro controlado del bootstrap demo

El retiro efectivo depende de que la provisión administrativa mínima exista y haya sido validada. Por ello se ejecutará en este orden:

1. Implementar y validar la provisión administrativa sin ejecutarla destructivamente sobre datos existentes.
2. Confirmar que el usuario, vehículo y SDA del MVP estén provisionados de forma coherente.
3. Retirar de la autenticación de producción la llamada automática a `ensureDemoDataSeeded`.
4. Confirmar que `main.dart` solo use Firebase real y que `main_dev.dart` conserve mocks y simulador.
5. Mantener los datos existentes hasta clasificarlos y ejecutar la tarea posterior de limpieza controlada.

El retiro no implica eliminar `FirebaseBootstrapService` o los datos existentes en el mismo cambio. Primero se impide su ejecución en producción; cualquier eliminación posterior requiere validación independiente.

## Orden de implementación de la ruta

1. Incorporar lectura dual y pruebas para `ts` sin modificar datos existentes.
2. Añadir `vehicleId` de forma aditiva y conservar temporalmente `userId`.
3. Incorporar el estado individual y migrar el comportamiento de reconocimiento con fallback controlado.
4. Blindar la fusión para no borrar cancelaciones.
5. Detenerse y validar la compatibilidad antes de iniciar la provisión administrativa mínima.
6. Después de validar la provisión, retirar la creación demo de producción y validar la separación DEV/producción como tarea independiente.

Cada paso debe validarse antes de continuar y no habilita automáticamente el siguiente.

## Criterios de aceptación

- [x] Flutter puede leer eventos con `ts` cadena, numérico, ausente o inválido sin perder el fallback por `receivedAt`.
- [x] Los eventos nuevos contienen `vehicleId` cuando existe asociación y siguen siendo consumibles durante la transición.
- [x] Los eventos históricos que solo contienen `userId` siguen siendo accesibles para el propietario autorizado en el flujo actual; las reglas finales se implementan por separado.
- [x] Reconocer un incidente afecta solamente al `uid` que realizó la acción.
- [x] Una retransmisión o enriquecimiento conserva la evidencia de cancelación en el alcance implementado: pruebas locales y validación real del escenario autorizado.
- [x] `main_dev.dart`, los mocks y el simulador continúan funcionando sin Firebase ni hardware, conforme a las pruebas dirigidas registradas.
- [x] No se eliminan datos reales o de prueba como parte de esta tarea.

### Criterio de la tarea posterior de retiro del bootstrap

- [ ] Un inicio de sesión de producción no crea usuario, vehículo ni dispositivo demo. Pendiente después de implementar y validar la provisión; no forma parte del cierre de los cuatro frentes de compatibilidad.

## Fuera de alcance

- reglas definitivas de RTDB;
- migración o limpieza de la instancia real;
- modelo canónico completo de la Fase 2;
- FCM y estados de entrega de notificaciones;
- RockBLOCK y deduplicación satelital;
- paginación, auditoría avanzada o soporte multiflota.
