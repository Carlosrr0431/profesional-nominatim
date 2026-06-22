# profesional-nominatim

Geocodificación **Nominatim** para ProfesionalApp (Salta).  
El dashboard usa **Google Places** para POIs; Nominatim cubre **calle + altura** y fallback OSM.

## Costos en Railway (optimizado)

| Ajuste | Valor runtime | Ahorro |
|--------|---------------|--------|
| Scale → Memory | **1.5 GB** (railway.toml) | Evita picos de 4 GB |
| Scale → CPU | **1 vCPU** | |
| **Serverless** | Activar en Deploy | ~70–85 % si hay poco tráfico |
| PostgreSQL tunado | 128 MB shared_buffers | Baja ~2 GB → ~1 GB |
| `GUNICORN_WORKERS` | `1` | Menos procesos API |
| `IMPORT_STYLE` | `address` (no `full`) | Base más chica (requiere reimport) |

### Variables recomendadas (runtime)

```env
NOMINATIM_PASSWORD=tu-secreto
FORCE_REIMPORT=false
FORCE_REEXTRACT=false
GUNICORN_WORKERS=1
WARMUP_ON_STARTUP=false
```

### Reducir aún más (opcional, requiere reimport ~1–2 h)

Solo Salta Capital + estilo `address` (suficiente con Google para comercios):

```env
IMPORT_REGION=capital
IMPORT_STYLE=address
FORCE_REIMPORT=true
```

Subir Memory a **4 GB** solo durante el import; luego volver a **1.5 GB** y `FORCE_REIMPORT=false`.

### PBF sin osmium en Railway

```env
PBF_URL=https://TU_PROYECTO.supabase.co/storage/v1/object/public/osm-data/salta.osm.pbf
```

## Railway rápido

1. Repo `profesional-nominatim` → Railway
2. Volumen **`/pgdata`** (5–10 GB)
3. `NOMINATIM_PASSWORD`
4. **Serverless ON**
5. Scale: **1.5 GB RAM**, **1 vCPU**

## Probar

```http
GET https://TU-URL.up.railway.app/search?q=Belgrano+1200+Salta&format=jsonv2&limit=3
GET https://TU-URL.up.railway.app/status
```

## driver-app

```env
EXPO_PUBLIC_NOMINATIM_URL=https://TU-URL.up.railway.app
EXPO_PUBLIC_NOMINATIM_SELF_HOSTED=true
```
