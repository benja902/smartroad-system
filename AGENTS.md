# Reglas permanentes de trabajo

- El objetivo principal es entregar una aplicación Android desarrollada con Flutter.
- `manual-sda (4).html` es la documentación vigente del dispositivo SDA y prevalece ante manuales anteriores.
- Firebase Realtime Database es actualmente el backend de datos; no migrar a Firestore sin una decisión explícita.
- El backend se alojará en Google Cloud y mantendrá Firebase Authentication, Realtime Database y FCM.
- No modificar el firmware del SDA.
- No exponer secretos, tokens, contraseñas, credenciales, claves MQTT ni archivos de configuración sensibles.
- No realizar cambios o refactors fuera del alcance de la tarea activa.
- Evitar leer `node_modules`, `build`, caches, dependencias instaladas y archivos generados salvo necesidad explícita.
- Mantener separados los repositorios, rutas y datos mock de las implementaciones de producción.
- Implementar una sola tarea funcional por vez.
- Validar cada cambio antes de continuar con la siguiente tarea.
