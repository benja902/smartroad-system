# Documento histórico — requerimientos de buzzer y persistencia de `seq`

> **Estado: histórico, no normativo.** Este documento registra hallazgos y requerimientos de una versión anterior del firmware. La referencia vigente del SDA es `manual-sda (4).html`.

Estado conocido al cerrar la línea base:

- El problema del buzzer fue reportado como corregido en el firmware final.
- RockBLOCK fue añadido posteriormente y su contrato vigente está documentado en `manual-sda (4).html` y `docs/device_contract.md`.
- La persistencia de `seq` después de apagar o reiniciar continúa pendiente de validación física con el prototipo.

El contenido siguiente se conserva como evidencia histórica de las pruebas realizadas sobre `SDA-E9A8D8`. No autoriza cambios de firmware ni reemplaza el contrato vigente.

## 1. Hallazgos históricos

### 1.1 El buzzer nunca se activa durante una alerta real
**Estado actualizado:** reportado como corregido en el firmware final; pendiente únicamente de confirmación durante las pruebas físicas end-to-end.

Confirmado con RTDB en vivo: `outputs.buzzer` se mantuvo en `false` durante todo el ciclo de una alerta grave (`pre_alarm`/`sending`/`alert_active`), en pruebas con batería y con USB-C (se descartó voltaje como causa). La configuración del equipo tiene "Buzzer activo" habilitado. El manual especifica pitidos cortos que aceleran en el último tercio de la prealarma y continúan intermitentes en la ventana de anulación hasta silenciarse a los 5 min — esa lógica no se está ejecutando o no está llegando a la salida física.

**Sugerencia de diagnóstico**: revisar si la rutina que acciona el pin del buzzer está en el mismo camino de código que el punto 1.2 (ver abajo) — podrían compartir causa raíz.

### 1.2 El equipo se queda atascado en `state: "sending"` sin publicar el evento
Observado en vivo: tras varias inclinaciones seguidas en poco tiempo, el equipo quedó en `sending` durante 58+ segundos sin publicar el evento correspondiente al tópico `sda/{id}/event`. El bridge no descartó ningún mensaje (no hay log de error) — simplemente nunca llegó nada. Se resolvió manualmente presionando CANCELAR. `sending` debería ser un estado de tránsito breve (segundos, no casi un minuto).

### 1.3 El contador `seq` se reinicia al apagar/encender el equipo
**Estado actualizado:** el manual vigente declara persistencia, pero falta validarla físicamente en el firmware final.

El campo `seq` es la clave de deduplicación en el servidor (`{deviceId}_{seq}`). Al reiniciarse a 1 después de cada apagado/encendido, un evento real nuevo puede caer en la misma clave que un evento viejo de una sesión anterior, heredando su estado ya procesado (confirmado en pruebas: un evento nuevo llegó marcado como "atendido" automáticamente por herencia de un evento viejo con la misma clave). Se aplicó un mitigante del lado del servidor (bridge), pero **la corrección correcta es que el firmware persista el último `seq` usado en memoria no volátil (NVS/flash)** y continúe desde ahí tras cada reinicio, en vez de reiniciar el contador.

## 2. Especificación acústica del buzzer

| Situación | Patrón propuesto | Objetivo |
|---|---|---|
| Operación normal | Silencio | No incomodar al conductor |
| Nivel leve | 1 pitido corto cada 2 s | Advertencia reconocible, no alarmante |
| Nivel moderado | 2 pitidos cortos cada 1 s | Mayor urgencia |
| Nivel grave | 3 pitidos rápidos cada 1 s | Máxima urgencia |
| Volcadura | Patrón de nivel grave | Siempre se considera grave, sin importar el ángulo |
| SOS por pulsación corta (con prealarma) | Patrón de nivel grave, acelerando en el último tercio | Igual que un choque grave detectado |
| **SOS por pulsación larga — 3 s (envío inmediato, sin cuenta regresiva)** | **Ir directo al patrón de "alerta enviada" (grave)** — no hay ventana de prealarma que sonar | El manual especifica que este camino no tiene cuenta regresiva; el patrón de prealarma no aplicaría aquí |
| Últimos 3 s antes de publicar (dentro de la prealarma) | Acelerar el patrón del nivel correspondiente | Indicar que la alerta está por enviarse |
| Alerta enviada correctamente | 3 pitidos de confirmación, luego recordatorio cada 15 s | Confirmar que MQTT/Firebase recibió la alerta |
| Alerta en cola por falta de conexión | 2 pitidos largos cada 10 s | Diferenciar detectado-pero-no-enviado de enviado |
| Alerta cancelada (botón CANCELAR) | 1 pitido largo | Confirmación clara de cancelación |
| Prueba del sistema (SOS+CANCELAR 5 s) | 2 pitidos cortos, una sola vez | No confundir con un accidente real |
| Falla técnica | 2 pitidos cada 60 s | Aviso técnico no urgente |

**Reglas generales**:
- El plazo de gracia (prealarma) se mantiene en su valor actual (10 s de fábrica); durante ese tiempo el buzzer usa el patrón del nivel ya detectado.
- Silenciar el buzzer (botón CANCELAR en operación normal) **nunca** cancela ni borra una alerta ya enviada — solo corta el sonido.
- El autosilenciado a los 5 minutos se mantiene como está.
- **El campo `acknowledged` que marca la app (Firebase/RTDB) no debe silenciar el buzzer físico.** El equipo no tiene ningún canal de vuelta desde Firebase — solo publica. Esa separación es intencional: el equipo es la única autoridad sobre su propio estado físico; la app solo refleja lo que el equipo publica.

## 3. Contrato de datos — no cambia

No renombrar ni modificar los valores de `type` ni `severity` (`crash`/`rollover`/`sos`/`cancel`/`test`/`power_loss`/`low_battery`/`booted` y `leve`/`moderado`/`grave`/`none`) — el bridge y la app Flutter ya están construidos sobre esos valores exactos tal como están documentados en `docs/device_contract.md`. Toda la lógica de esta propuesta es interna al firmware (accionar el buzzer, persistir `seq`), no afecta el payload publicado.

## 4. Severidad — confirmado, sin cambios pendientes

El ingeniero confirmó que `severity_for()` en `src/core/detector.cpp` ya implementa la tabla de umbrales del manual (15/25/40 g, 8/20 km/h delta-V, volcadura siempre grave). Validado en la práctica: todas las pruebas de volcadura dieron `grave` consistentemente, como corresponde. **Pendiente de validar en la práctica** (no de firmware): un impacto real de baja magnitud que produzca `type: crash, severity: leve` o `moderado` — hasta ahora solo se probó `rollover`, que siempre fuerza `grave` por diseño.
