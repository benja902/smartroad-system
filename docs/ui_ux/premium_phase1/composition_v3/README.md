# Composition v3 — referencia del Motion actual

16 de octubre de 2026. **Referencia para corregir el prototipo; no aprueba una variante ni implementación Flutter.**

[Abrir mapa y storyboard](index.html). El reproductor y todos los controles siguen únicamente en [Motion Prototype 01](../motion_prototype_01/index.html).

## Fuente y regeneración

`generate.mjs` abre el Motion existente en Chrome headless instalado, espera la fuente local y llama a sus funciones públicas `setMode`/`seek`. Exporta la escena SVG que el propio prototipo dibuja, incluyendo el formulario visible con sus estilos calculados. No implementa otro renderer, trayectoria, reloj ni lógica de reproducción. Los SVG se incorporan en una sola página estática; no son nuevas fuentes de ilustración para editar manualmente.

```text
Motion actual: assets.js + vehicle.js + prototype.js + HTML/CSS + logo
                               ↓ generate.mjs
                index.html + manifest.json + capturas de revisión
```

Desde la raíz del repositorio:

```sh
node docs/ui_ux/premium_phase1/composition_v3/generate.mjs
node docs/ui_ux/premium_phase1/composition_v3/generate.mjs --check
```

El primer comando regenera las instantáneas y verifica la página con Node/Chrome existentes; no instala dependencias. El segundo solo comprueba si los hashes de las fuentes siguen coincidiendo. **Después de editar Motion hay que regenerar v3**. No se actualiza sola al abrirla y sus imágenes no deben convertirse en una copia independiente que se edita por separado.

`manifest.json` identifica fuentes y hashes, variantes, tiempos y objetos. v2 se conserva como antecedente histórico. El mapa usa la escena actual con el vehículo al final y el isotipo en el destino; normaliza únicamente su encuadre para colocar etiquetas legibles. Es una lámina de identificación, no un fotograma adicional de la animación.

## Cómo pedir correcciones

- Composición: «Quita T3 de toda la escena» o «Mueve T6 más lejos de la casa».
- Tiempo: «En A, a 650 ms, T2 todavía no debería aparecer».
- Movimiento: «En B, a 3100 ms, el isotipo debería pasar más a la derecha».
- Superposición: «En este fotograma el vehículo tapa el árbol». Adjuntar captura y señalarlo también sirve; no hace falta conocer el ID.

Los códigos T1–T6 se asignan al árbol completo. No designan archivos SVG ni fotogramas. Sus IDs internos permiten localizar la pieza exacta. La corrección se realiza en el recurso o en el código de animación de Motion según corresponda y después se regenera esta referencia. Cambiar solo una imagen del storyboard no cambiaría la animación.

## Alcance y límites

Se documentan cuatro estados iniciales compartidos por A/B, seis estados posteriores por cada una, diez estados específicos de C (600/720/840/960 ms y seis posteriores) y diez de D (840/1560/2160/2400 ms y seis posteriores). Son **36 instantáneas**, no todos los fotogramas ni una prueba de interpolación continua. Los enlaces llevan al reproductor existente detenido en el tiempo indicado; no hay botones de reproducción nuevos.

**C — Impulso refinado:** T4 ausente; isotipo en la posición original, entrada 720–960 ms (120 ms después del inicio del auto). Conserva impulso y entrega de A. El mapa mantiene T4 identificado para comparar A/B; en C ese objeto está oculto. Las propuestas SVG de `proposals/` se conservan y no se sobrescriben al regenerar.

**D — Baliza flotante:** conserva C para comparar y añade una elevación/regreso de 2 unidades de 960 a 2160 ms, sombra tenue (`target-shadow`), reposo antes del encuentro y reacción de 3 unidades con onda única en la base a 2400 ms. Sin T4 ni cambios al vehículo. Se documenta en el mismo storyboard y abre el mismo reproductor con `mode=beacon`. El mapa general sigue representando A; la sombra es exclusiva de D, no un objeto funcional o indicador de conectividad.

El formulario exportado es una captura vectorial con `foreignObject` y estilos calculados: puede presentar diferencias de renderizado al exportar a herramientas que no soporten HTML dentro de SVG. La referencia visual es Chrome y el Motion original, con fuente Manrope local. No hay autenticación ni servicios reales.

El mapa, los tiempos y la comparación A/B sirven para revisión humana; no certifican accesibilidad o rendimiento Android. Las validaciones completas de reproducción siguen en `motion_prototype_01/verify_browser.mjs` y su informe; generar v3 no vuelve a ejecutar esa batería.

No se modifica Flutter, Design System global, Firebase, bridge ni cambios funcionales. No se hacen commits/push. SDA apagado y bridge detenido; app/celular, Internet y Firebase no son necesarios para revisar.
