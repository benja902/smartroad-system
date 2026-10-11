# Referencias visuales históricas de SmartRoad

Este material proviene de diseños anteriores en Stitch. Sirve para **apariencia, jerarquía y composición visual**, no como contrato funcional ni prueba de que una pantalla esté implementada. `DESIGN_SYSTEM.md` reúne colores, tipografía y espaciados. Los archivos disponibles son `screen.png` y `code.html` en cada carpeta: `home/`, `alerts/`, `emergency_level2/` y `emergency_level3/`. El HTML es referencia de estructura; no se copia literalmente a Flutter.

Las etiquetas anteriores «FINAL» o «FINAL BASE» significaban cierre del diseño visual, **no** aceptación funcional. En particular, los diseños de Nivel 2 muestran una cuenta regresiva de 15 segundos y controles «Necesito ayuda ahora»/«Cancelar alerta». El flujo Flutter actual **no** ofrece ese countdown ni cancelación desde la app: el preaviso ocurre en el SDA y la UI presenta el incidente recibido. `lib/screens/emergency/active_emergency_screen.dart` y `test/emergency_flow_test.dart` describen y prueban ese comportamiento actual. No reintroducir el flujo de Stitch sin una tarea funcional explícita.

Las pantallas principales (Inicio, Alertas, Vehículo, Historial, Perfil) y las emergencias pueden tomar estas imágenes como guía visual. Su navegación y reglas vigentes se determinan por el código, pruebas y especificaciones actuales, no por este índice histórico.

Orden de autoridad ante discrepancias: `manual-sda (4).html` y `docs/device_contract.md` para comportamiento del SDA; código y pruebas para implementación actual; `docs/IMPLEMENTATION_PLAN.md` y especificación de la tarea para comportamiento planificado. Los diseños solo orientan la presentación.
