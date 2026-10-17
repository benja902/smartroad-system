# Inicio — comparación Flutter DEV A/B

**Revisión artística posterior:** A/B se conservan como referencias funcionales, pero el usuario no las aprobó como dirección artística. Las nuevas C — Guardian Deck y D — Signal Flow están descritas en [SIGNATURE_CD.md](SIGNATURE_CD.md). Ninguna modifica el valor predeterminado MAIN ni queda aprobada por su implementación.

Estado: definición funcional aprobada; **composiciones pendientes de revisión visual humana**. Inicio actual sigue siendo el valor inicial en DEV y el único utilizado en MAIN. Sin commit ni push.

## Composiciones

| A · Vehicle Focus | B · Contextual Focus |
| --- | --- |
| Superficie Navy de vehículo con marca/modelo, placa y silueta compacta de 70 dp. | Disponibilidad reportada en superficie clara protagonista, con tipografía de mayor jerarquía. |
| Disponibilidad y comunicación en sección abierta, sin segunda tarjeta idéntica al hero. | Vehículo/placa en bloque secundario compacto, sin ilustración. |
| Posición, conectividad desplegable y actividad reciente después del resumen. | Misma información y acciones, dando prioridad al estado reportado y consulta. |

En ambos: saludo del usuario, atención contextual antes de los resúmenes cuando corresponde, posición informativa sin mapa, hasta tres eventos con la clasificación existente y acceso a Alertas. Contactos/Historial adicionales no aparecen en el contenido; sus rutas y tabs permanecen. No se añaden batería, RSSI, microSD o diagnósticos al nuevo Inicio.

La silueta A adapta en pintura nativa el recurso decorativo `#vehicle-profile` del HTML existente; no representa fotográficamente el vehículo asociado. Es una pieza estática, sin runtime SVG o dependencia nueva. Paleta local: Navy `#031B3B`, Aqua `#14E0D3` limitado al dibujo, Teal `#006D68`, blanco y canvas `#F8F9FA`; Manrope existente. Sin cambios globales de AppTheme. Los valores del estado no se presentan como garantías de protección.

## Reutilización y aislamiento

- `HomeScreen` conserva sus suscripciones y selección de atención. Pasa valores/callbacks al único `PremiumHomeContent`; no se duplican Providers, consultas o clasificación entre A/B.
- `HomeVisualPreview` contiene enum/scope de revisión. `DevNavigationReview` instala su selección en el menú DEV existente; `HomeScreen` exige además `DevModeFlag`. MAIN ignora incluso un scope experimental suministrado accidentalmente.
- `PremiumHomeContent` comparte los mismos bloques de vehículo, disponibilidad, posición, conectividad y actividad. A/B cambian prominencia y orden de esos bloques. Mantiene un scroll común al alternar A/B y al volver de otras ramas.
- `RecentAlertsPreview` conserva filtro, orden y límite; una opción `neutralEmpty` cambia únicamente el mensaje vacío en A/B. Su valor predeterminado conserva Inicio actual.
- `AttentionBanner` conserva callbacks/reconocimiento/contador. La opción `animateIcon: false` deja el icono estático en A/B; su valor predeterminado conserva las vistas anteriores. No se añade un pulso nuevo ni se altera el incidente.
- Se reutiliza `ScreenEntrance` (240 ms, una entrada por montaje, compatible con movimiento reducido). El desplegable usa 180 ms o cero con reducción de movimiento. Pill Active y su transición de ramas no se modifican.

## Datos, escenarios y límites

Comprobado con los mocks existentes: datos disponibles, desconexión reportada, GNSS sin fix, atención moderada, reconocimiento personal y prioridad de SOS. No se cambian sus controles ni se agregan estados al simulador.

Ausencia de vehículo/estado/GNSS, fecha de época cero y mensaje de error se verifican por inyección de valores de presentación en pruebas. Además, una fuente de error **exclusiva del test** verifica que `EventProvider.error` llega a Home por su contrato de stream; no crea un escenario nuevo en la app. No se contacta Firebase.

La UI usa mensajes neutrales ante null. Omite la fecha de comunicación si no es utilizable (época cero); no introduce caducidad/TTL. Con GNSS sin fix no presenta el 0,0 del mock como última posición válida. Con fix muestra coordenadas del dato recibido, sin afirmar actualidad ni seguimiento. El desplegable expone tecnología, registro celular y fix reportados; no recalcula salud o vigencia.

Limitaciones conservadas: null ambiguo en V/D; lista E vacía puede ser inicial; E.error no distingue lectura/acuse; `online`/otros booleanos pueden contener defaults del parser; no hay política de frescura ni reintento. Un error genérico no declara que desaparecieron los incidentes. Detalle de incidente, Vehículo e Historial siguen placeholders. El manejo asíncrono del botón de reconocimiento no se amplía en este incremento.

## Validación

- `flutter test --no-pub -r expanded test/home_visual_preview_test.dart`: **12/12 satisfactorias**.
- `test/navigation_visual_preview_test.dart`: **22/22 regresiones satisfactorias**, ejecutadas junto a la primera pasada de Inicio; los fallos iniciales de búsqueda/desplazamiento de las pruebas de Inicio se corrigieron y sus 12 casos finales pasan. No se repite la batería global.
- Análisis estático de los siete Dart afectados: **sin incidencias**. Tres avisos de llaves en `RecentAlertsPreview` quedaron corregidos, sin cambiar sus decisiones.
- Pruebas: MAIN conserva actual y rechaza scope experimental, selección A/B sin reemplazar Providers ni perder scroll, regreso de Vehículo, reconocimiento, acceso a Alertas, emergencia fuera del shell, ausencia/error, 320/390 × 640 dp con texto 200 %, apertura del desplegable, activación del acceso por teclado, área de ese botón ≥48 dp y movimiento reducido sin frames pendientes después de estabilizar.
- No se abrió Edge ni se generaron capturas; no se utilizó dispositivo físico, hardware o servicios reales. Revisión visual, TalkBack, SafeArea/teclado de dispositivo y medición UI/raster en Android siguen pendientes; los widget tests no certifican rendimiento físico.

## Cómo comparar

1. Ejecutar `flutter run -t lib/main_dev.dart -d edge`. Si ya está corriendo, Hot Reload; si la sesión anterior no incorpora el scope nuevo, Hot Restart.
2. Omitir o completar D, iniciar sesión mock y abrir el menú de ajustes encima del botón del panel DEV (el mismo de comparación de navegación).
3. Elegir **A · Vehicle Focus**, **B · Contextual Focus** o **Inicio actual**. Las opciones Actual/Underline/Pill de navegación siguen independientes en ese menú. Ninguna selección cambia la configuración MAIN.
4. Para comparar condiciones, usar el panel DEV existente: desconexión del dispositivo, GNSS offline y choque moderado. Volver a Inicio; usar SOS únicamente cuando se quiera revisar el flujo crítico mock. No hay controles nuevos para simular ausencia total o error de lectura.

Solo requiere la app DEV local y Edge; SDA, bridge, celular físico y servicios Firebase no se utilizan y pueden permanecer apagados. No se requiere Internet para los mocks. Detenerse aquí para elegir dirección visual; no implementar Vehículo ni promover A/B a predeterminada sin aprobación.
