# Reglas permanentes de trabajo

- El objetivo principal es entregar una aplicación Android desarrollada con Flutter para el MVP de un vehículo y un SDA. `manual-sda (4).html` es la fuente técnica vigente del dispositivo; los manuales anteriores son históricos. No modificar el firmware.
- Firebase Authentication, Realtime Database y FCM permanecen en la arquitectura; no migrar a Firestore sin decisión explícita. El backend objetivo se alojará en Google Cloud, pero no se debe confundir arquitectura prevista con despliegue existente.
- Para el estado implementado prevalecen código y pruebas; para el orden de trabajo, `docs/IMPLEMENTATION_PLAN.md`; para el siguiente bloque, `docs/PHASE2_INCIDENT_SPEC.md`. Una `DECISIÓN ABIERTA` no autoriza inventar política.
- Mantener separados `main.dart` y repositorios Firebase reales de `main_dev.dart`, mocks y simulador. No ampliar a multi-vehículo, multi-SDA ni sincronizar contactos SmartRoad con destinatarios SMS del firmware sin tarea aprobada.
- Implementar una tarea funcional por vez, de forma incremental, preservar los cambios locales ajenos y validar antes de marcarla completada. No hacer commit ni push salvo petición explícita. Evitar leer dependencias instaladas, `node_modules`, `build`, cachés y archivos generados salvo necesidad explícita.

## Autonomía local

El agente puede, dentro de una tarea autorizada, inspeccionar el repositorio, modificar código y documentación locales, crear pruebas, ejecutar tests y linters, utilizar emuladores locales, corregir fallos y repetir la validación sin solicitar confirmación por cada archivo o prueba. Las pruebas se ejecutan en primer plano con salida de progreso (`-r expanded` para Flutter); si transcurren 60 segundos sin salida, detener el proceso y comunicar el último punto conocido. Usar proyectos y datos ficticios en Emulator.

## Detenerse antes de acciones reales o sensibles

Solicitar autorización explícita **antes** de modificar Firebase real (incluidas reglas o configuración), crear/habilitar/modificar cuentas Auth reales, escribir o borrar datos reales, desplegar a producción, realizar operaciones destructivas, usar hardware físico, enviar comunicaciones satelitales o efectuar acciones que puedan generar costes. Detenerse también si falta un dato privado o se requeriría solicitar o manipular un secreto no disponible; no buscarlo, derivarlo ni mostrarlo. No registrar UID, IMEI, correos reales, tokens, contraseñas, credenciales MQTT, claves ni archivos de configuración sensibles en documentación, fixtures, logs o respuestas.

Cuando una decisión funcional no esté definida y cambie el resultado, documentar alternativas e impacto y pedirla antes de implementar esa parte. Antes de una pausa, indicar lo realizado, pruebas y resultado, motivo de la intervención humana y exactamente qué debe estar encendido o apagado (SDA, bridge, app/celular, Internet y Firebase).
