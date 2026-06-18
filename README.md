# profesional-nominatim

Servidor de geocodificación **Nominatim** para ProfesionalApp (Salta, Argentina).  
Despliegue en [Railway](https://railway.app) — **sin pasos locales**.

## Railway (5 minutos)

1. Creá un repo vacío en GitHub: `profesional-nominatim`
2. Subí este código (`git push`)
3. En Railway → **New Project** → **Deploy from GitHub** → elegí `profesional-nominatim`
4. **Volumes** → montá `/var/lib/postgresql/16/main` (10 GB+)
5. **Variables** → `NOMINATIM_PASSWORD` = contraseña segura
6. **Networking** → **Generate Domain**
7. Primer deploy: **1–3 horas** de import. No reinicies hasta que `/status` responda.

## Probar

```http
GET https://TU-URL.up.railway.app/search?q=Belgrano+1200+Salta&format=jsonv2
GET https://TU-URL.up.railway.app/status
```

## driver-app

```env
EXPO_PUBLIC_NOMINATIM_URL=https://TU-URL.up.railway.app
EXPO_PUBLIC_NOMINATIM_USER_AGENT=ProfesionalConductorDriverApp/1.0
EXPO_PUBLIC_NOMINATIM_SELF_HOSTED=true
```

## Requisitos

| Recurso | Valor |
|---------|-------|
| RAM     | **8 GB** recomendado |
| Volumen | `/var/lib/postgresql/16/main` obligatorio |

## Descarga del mapa (mirrors)

Railway **no puede** conectar a `download.geofabrik.de`. El entrypoint prueba en orden:

1. `PBF_URL` (si la definís vos — recomendado si fallan todos los mirrors)
2. GitHub Release `salta-data-v1` (requiere Actions o subida manual)
3. **BBBike** + recorte Salta con osmium

### Si GitHub Actions falla por billing

Opción A — **Arreglar billing** en https://github.com/settings/billing y correr el workflow.

Opción B — **Subir el PBF a Supabase Storage** (bucket público) y en Railway:

```env
PBF_URL=https://TU_PROYECTO.supabase.co/storage/v1/object/public/osm-data/salta.osm.pbf
```

Opción C — Redeploy con el último código (intenta BBBike automáticamente).

## Solución de problemas

| Síntoma | Causa | Acción |
|---------|-------|--------|
| **No running instances** / 502 | Health check o crash en import | Redeploy tras quitar healthcheck; revisar **Deployments → logs** |
| Import reinicia en loop | Poca RAM | Subir a **8 GB** en Settings → Scale |
| Permission denied en volumen | Usuario sin permisos | Variable `RAILWAY_RUN_UID=0` (ya en Dockerfile) |

**Primer deploy:** el import tarda **1–3 horas**. La consola puede mostrar "No running instances" mientras el contenedor trabaja; mirá los logs en **Deployments**, no en Console.

| Variable | Default | Descripción |
|----------|---------|-------------|
| `THREADS` | `2` | Hilos de import |
| `SALTA_BBOX` | provincia Salta | Bbox osmium |
