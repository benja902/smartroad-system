# Paquete de referencias visuales — URBES (v1)

Incluye los tres videos proporcionados en la conversación, fotogramas clave, una captura del prototipo existente y `ANIMATION_REFERENCES.md` con observaciones, propuesta provisional y restricciones.

## Cómo entregarlo a Codex en VS Code

1. Descomprime **en una carpeta local de referencia** (por ejemplo, `D:\smartroad\docs\ui_ux\premium_phase1\references\`).
2. En el chat de Codex indica la **ruta exacta** del archivo `ANIMATION_REFERENCES.md`; no basta con citar Beeway/Parcel/Skyward por nombre.
3. Los videos se incluyen para consulta humana. Si Codex no puede inspeccionar MP4 directamente, usa las imágenes de `fotogramas/` y el documento. No presupongas que visualizó el video hasta confirmarlo.
4. **No incluyas automáticamente los MP4 en Git** ni en el paquete de assets de Flutter: son material referencial externo; conserva los archivos fuera de Git o ignóralos temporalmente y revisa licencias/derechos de uso.
5. Autoriza **solo** composición/guion visual, no implementación.

## Mensaje breve para Codex

> La auditoría diferencial fue recibida. Te adjunto `ANIMATION_REFERENCES.md` y la carpeta `fotogramas/` (con los MP4 como apoyo). Lee el documento y revisa lo que puedas observar de las imágenes. Antes de implementar, entrega dos composiciones estáticas del Splash (Beeway-capas y Parcel-ruta), una del Login coherente con la elegida y el storyboard de transición Splash→Login/destino. Preserva Brand Intro 01 en DEV, las reglas de emergencia y movimiento reducido, formulario y autenticación existente. No modifiques código ni instales dependencias todavía. Señala lo que no pudiste verificar de los videos.
