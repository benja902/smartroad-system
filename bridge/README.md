# Bridge MQTT → Firebase Realtime Database

## Estado actual

Este servicio Node.js es independiente de Flutter. `index.js` mantiene una conexión MQTT TLS con sesión persistente y consume `availability`, `status`, `position` y `event`; el validador contrasta `id` con el topic y `event_writer.js` conserva eventos en `events/{deviceId}_{seq}` mediante transacciones. Los bloques opcionales malformados se descartan con diagnósticos de código fijo. La recuperación de cancelaciones y el acuse MQTT ante fallos siguen pendientes de 2.1c; la clasificación Flutter de tipos desconocidos, de 2.1d. **No hay despliegue cloud validado** ni webhook Ground Control/Iridium.

## Ejecución local

Instalar dependencias desde el lockfile y ejecutar desde `bridge/` para que el punto de entrada encuentre `.env` en el directorio de trabajo. Verificar que la versión local de Node proporcione `process.loadEnvFile` (el `engines` del paquete, por sí solo, no garantiza esa API):

```powershell
cd bridge
npm ci
npm start
```

`bridge/.env` es privado y está ignorado. Debe contener `DATABASE_URL`, `MQTT_HOST`, `MQTT_PASS` y, si difieren de los valores predeterminados, `MQTT_USER` y `MQTT_PREFIX`. Se requieren credenciales de Firebase Admin fuera del repositorio, disponibles para Application Default Credentials. No copiar valores reales a documentación, comandos compartidos, logs o fixtures. Este arranque **conecta con servicios reales y escribe RTDB**; requiere autorización y configuración deliberadas. Para trabajo autónomo usar pruebas locales y Emulator, no este comando.

`index.js` llama actualmente `loadEnvFile('.env')` sin condición. Por ello, aunque se definan variables de entorno en el sistema, el proceso falla si falta ese archivo en su directorio de trabajo. No interpretar una receta basada solo en `--set-env-vars` como suficiente.

## Pruebas locales sin MQTT ni Firebase real

Desde la raíz del repositorio, en primer plano:

```powershell
npm --prefix bridge test
```

El runner nativo de Node muestra progreso con `--test-reporter=spec`; `-r expanded` corresponde a Flutter. Si pasan 60 segundos sin salida, detener con `Ctrl+C` e informar el último punto conocido. La suite ordinaria usa base y asociaciones ficticias; no carga `.env`, MQTT ni SDA. La prueba con Firebase Admin se omite salvo dentro de Database Emulator con `FIREBASE_DATABASE_EMULATOR_HOST=127.0.0.1:19000` y `GCLOUD_PROJECT=demo-smartroad-bridge`. No emplear un proyecto real para esa prueba.

## Despliegue cloud: futuro, no receta ejecutable actual

La Fase 8 del plan decidirá topología, Secret Manager, identidad de servicio, instalación reproducible, supervisión y recuperación. El `Dockerfile` actual no copia `.env`, mientras `index.js` lo exige; por tanto el antiguo ejemplo de Cloud Run con solo variables/secrets **no debe ejecutarse como despliegue funcional**. Tampoco se ha validado la estrategia final de proceso MQTT persistente, permisos mínimos o salud en Google Cloud. Resolver y probar esos puntos en la tarea de despliegue antes de publicar; no incluir credenciales privadas en la imagen ni conceder permisos amplios por conveniencia.

## Límites

No utiliza Firestore. No publica comandos `ping`, `position` ni `diag` hacia el SDA. No implementa FCM, webhook Iridium ni consultas de contacto. La referencia técnica del dispositivo es `docs/device_contract.md` y, ante discrepancia de firmware, `manual-sda (4).html`.
