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
