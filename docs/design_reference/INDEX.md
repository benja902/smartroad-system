# URBES Design References

Este directorio contiene las referencias visuales de las pantallas diseñadas previamente en Stitch.

## Sistema visual global

- `DESIGN_SYSTEM.md`

Este archivo define:

- paleta de colores
- tipografía
- espaciados
- bordes
- radios
- sombras
- reglas visuales generales

Debe usarse como referencia global para toda la aplicación.

---

# Pantallas principales

## Home

Archivos:

- `home/home.png`
- `home/home.html`

Estado: FINAL

Tipo:
Pantalla principal de navegación.

Debe formar parte del flujo normal de la aplicación y utilizar la barra inferior de navegación.

---

## Alertas

Archivos:

- `alerts/alerts.png`
- `alerts/alerts.html`

Estado: FINAL

Tipo:
Pantalla principal de navegación.

Debe formar parte del flujo normal de la aplicación y utilizar la barra inferior de navegación.

Esta pantalla agrupa:

- alertas activas
- eventos informativos
- estado técnico
- historial reciente

---

# Flujos críticos

## Emergencia Nivel 2

Archivos:

- `emergency_level2/level2.png`
- `emergency_level2/level2.html`

Estado: FINAL BASE

Tipo:
Flujo crítico temporal.

IMPORTANTE:

Esta pantalla NO es un módulo de la barra inferior.

NO debe aparecer como opción del menú principal.

Se abre automáticamente cuando existe un evento de accidente Nivel 2.

Características principales:

- pantalla completa
- sin BottomNavigationBar
- cuenta regresiva de 15 segundos
- opción "Necesito ayuda ahora"
- opción "Cancelar alerta"
- preparación de ubicación y datos de emergencia

Flujo esperado:

Nivel 2 detectado
→ pendingConfirmation
→ mostrar esta pantalla
→ el usuario puede cancelar
→ el usuario puede confirmar ayuda inmediata
→ si termina el countdown, se confirma automáticamente la emergencia

---

## Emergencia Nivel 3

Archivos:

- `emergency_level3/level3.png`
- `emergency_level3/level3.html`

Estado: FINAL BASE

Tipo:
Flujo crítico temporal.

IMPORTANTE:

Esta pantalla NO es un módulo de la barra inferior.

NO debe aparecer como opción del menú principal.

Se abre automáticamente cuando existe un evento de accidente Nivel 3.

Características principales:

- pantalla completa
- sin BottomNavigationBar
- sin cuenta regresiva
- sin opción de cancelar
- protocolo de emergencia activado automáticamente
- ubicación del incidente
- mapa
- vehículo
- hora
- origen de detección
- estado del protocolo de emergencia
- botón "Ver incidente"
- botón "Llamar a emergencias"

Flujo esperado:

Nivel 3 detectado
→ emergencyActive
→ mostrar esta pantalla inmediatamente

---

# Navegación principal de la aplicación

Los módulos principales serán:

1. Inicio
2. Alertas
3. Vehículo
4. Historial
5. Perfil

Estas pantallas deben compartir una sola barra inferior reutilizable.

No duplicar una BottomNavigationBar distinta en cada pantalla.

---

# Distinción importante

Las pantallas:

- Home
- Alertas
- Vehículo
- Historial
- Perfil

son módulos normales de navegación.

Las pantallas:

- Emergencia Nivel 2
- Emergencia Nivel 3

son flujos críticos temporales y deben abrirse automáticamente según el estado del evento.

Ejemplo:

Home / Alertas / otro módulo
→ se detecta accidente
→ Nivel 2 o Nivel 3
→ pantalla crítica correspondiente
→ evento resuelto o cerrado
→ volver al flujo normal de la aplicación

---

# Prioridad para interpretar los diseños

Al reconstruir una pantalla en Flutter:

1. PNG
   - referencia visual final
   - apariencia real
   - proporciones
   - distribución visual

2. HTML
   - estructura
   - tamaños
   - iconos
   - espaciados
   - textos
   - jerarquía de componentes

3. DESIGN_SYSTEM.md
   - colores
   - tipografía
   - radios
   - sombras
   - reglas visuales globales

El HTML NO debe copiarse directamente a Flutter.

Debe reconstruirse utilizando widgets Flutter nativos, reutilizables y mantenibles.

Los textos e iconos pueden ajustarse durante el desarrollo si es necesario, siempre que se mantenga la intención visual y funcional del diseño.