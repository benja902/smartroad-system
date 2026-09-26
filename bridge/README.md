# Puente URBES SDA — MQTT → Realtime Database

Servicio independiente (Node.js, no forma parte de la app Flutter) que mantiene la conexión MQTT con el broker del equipo SDA y escribe en Firebase Realtime Database con el shape exacto de `docs/device_contract.md`. Corresponde a la sección 8 del manual del hardware, adaptado de Firestore a Realtime Database.

## Qué necesitas antes de desplegar

1. **Contraseña MQTT real del broker** — viene con la unidad de hardware, no está en este repo. Host y usuario ya están fijados por el manual:
   - Host: `3da4c64f2d3841abaa515824b7592e7c.s1.eu.hivemq.cloud`
   - Usuario: `lilygo`
2. **Google Cloud CLI** (`gcloud`) instalado y autenticado con una cuenta que tenga permisos sobre el proyecto `smartroad-system-3b23e` (Cloud Run Admin + Service Account User, como mínimo). Descarga: https://cloud.google.com/sdk/docs/install
3. Habilitar las APIs de Cloud Run y Secret Manager en el proyecto (una sola vez):
   ```
   gcloud services enable run.googleapis.com secretmanager.googleapis.com --project smartroad-system-3b23e
   ```

## Guardar la contraseña MQTT como secreto

```
echo -n "TU_CONTRASENA_MQTT_REAL" | gcloud secrets create mqtt-pass --data-file=- --project smartroad-system-3b23e
```

Si el secreto ya existe y quieres actualizarlo:
```
echo -n "TU_CONTRASENA_MQTT_REAL" | gcloud secrets versions add mqtt-pass --data-file=- --project smartroad-system-3b23e
```

## Permisos del servicio (para poder escribir en Realtime Database)

Cloud Run usa por defecto la cuenta de servicio de cómputo del proyecto. Dale permiso de administrador de Realtime Database:

```
gcloud projects add-iam-policy-binding smartroad-system-3b23e \
  --member="serviceAccount:$(gcloud projects describe smartroad-system-3b23e --format='value(projectNumber)')-compute@developer.gserviceaccount.com" \
  --role="roles/firebasedatabase.admin"
```

## Desplegar

Desde la carpeta `bridge/`:

```
gcloud run deploy puente-urbes-sda \
  --source . \
  --project smartroad-system-3b23e \
  --region southamerica-west1 \
  --min-instances 1 \
  --max-instances 1 \
  --no-cpu-throttling \
  --no-allow-unauthenticated \
  --set-env-vars MQTT_HOST=3da4c64f2d3841abaa515824b7592e7c.s1.eu.hivemq.cloud,MQTT_USER=lilygo,MQTT_PREFIX=sda,DATABASE_URL=https://smartroad-system-3b23e-default-rtdb.firebaseio.com \
  --set-secrets MQTT_PASS=mqtt-pass:latest
```

Notas sobre las banderas (igual que en el manual, sección 8.2):
- `--min-instances 1` + `--no-cpu-throttling`: mantienen el proceso vivo entre peticiones — imprescindible para sostener la conexión MQTT persistente.
- `--max-instances 1`: evita que dos instancias compartan el mismo `clientId` MQTT (el broker desconectaría a la anterior).
- `--no-allow-unauthenticated`: el servicio no expone ningún endpoint público útil (solo una sonda de salud), no necesita estar accesible desde internet.

## Verificar que está corriendo

```
gcloud run services logs read puente-urbes-sda --project smartroad-system-3b23e --region southamerica-west1 --limit 50
```

Deberías ver `puente conectado al broker MQTT`, y luego `evento guardado: ...` cada vez que el equipo publique un evento real.

## Qué NO hace este puente (a propósito, fuera del MVP)

- No escucha `sda/{id}/cmd/resp` ni publica comandos (`ping`/`position`/`diag` on-demand) — esa función queda para una fase posterior.
- No usa Firestore ni `collectionGroup` — todo es Realtime Database, con `events/{deviceId}_{seq}` como colección plana, tal como se decidió explícitamente para este proyecto.
