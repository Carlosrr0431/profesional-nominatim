#!/bin/bash
set -euo pipefail

LISTEN_PORT="${PORT:-8080}"
DATA_DIR="/nominatim/data"
SALTA_PBF="${DATA_DIR}/salta.osm.pbf"
SALTA_BBOX="${SALTA_BBOX:--68.75,-26.62,-62.00,-21.78}"
USER_AGENT="${USER_AGENT:-ProfesionalApp-Nominatim/1.0 (contacto@profesional.app)}"

MIRROR_BBBIKE="https://download3.bbbike.org/osm/pbf/region/south-america/argentina.osm.pbf"
MIRROR_GEOFABRIK="https://download.geofabrik.de/south-america/argentina-latest.osm.pbf"

echo "[nominatim] === Arranque $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
free -h 2>/dev/null || true
df -h / /var/lib/postgresql/16/main /nominatim 2>/dev/null || df -h

mkdir -p "${DATA_DIR}"

# Railway monta el volumen en /var/lib/postgresql/16/main y crea lost+found.
# PostgreSQL no puede initdb ahí; usamos un subdirectorio.
setup_postgres_data_dir() {
  local default_main="/var/lib/postgresql/16/main"
  local pgdata="${default_main}/postgres16"

  if mountpoint -q /pgdata 2>/dev/null; then
    pgdata="/pgdata/postgres16"
    echo "[nominatim] Volumen en /pgdata → ${pgdata}"
  elif [ -d "${default_main}/lost+found" ]; then
    echo "[nominatim] Volumen en ${default_main} (lost+found) → subdir ${pgdata}"
  elif mountpoint -q "${default_main}" 2>/dev/null; then
    echo "[nominatim] Volumen montado en ${default_main} → subdir ${pgdata}"
  else
    pgdata="${default_main}"
    echo "[nominatim] Sin volumen dedicado → ${pgdata}"
  fi

  mkdir -p "${pgdata}"
  chown -R postgres:postgres "${pgdata}" 2>/dev/null || true
  chmod 700 "${pgdata}" 2>/dev/null || true

  if ! grep -q "${pgdata}" /app/init.sh 2>/dev/null; then
    sed -i "s|/var/lib/postgresql/16/main|${pgdata}|g" /app/init.sh /app/start.sh
    if [ -f /etc/postgresql/16/main/postgresql.conf ]; then
      sed -i "s|/var/lib/postgresql/16/main|${pgdata}|g" /etc/postgresql/16/main/postgresql.conf
    fi
    echo "[nominatim] PostgreSQL data dir: ${pgdata}"
  fi
}

setup_postgres_data_dir

# Un intento rápido (sin loop) — para URLs opcionales.
try_once() {
  local dest="$1"
  local url="$2"
  echo "[nominatim] Prueba rápida: ${url}"
  curl -fsSL -A "${USER_AGENT}" --connect-timeout 30 --max-time 7200 -o "${dest}" "${url}"
}

# Reintentos largos — solo para mirrors principales.
download_with_retries() {
  local dest="$1"
  shift
  local url attempt=1

  while [ "$attempt" -le 25 ]; do
    for url in "$@"; do
      [ -z "$url" ] && continue
      echo "[nominatim] Descarga intento ${attempt}: ${url}"
      if curl -fsSL -A "${USER_AGENT}" --connect-timeout 60 --max-time 7200 -C - -o "${dest}.part" "${url}"; then
        mv -f "${dest}.part" "${dest}"
        echo "[nominatim] OK: $(ls -lh "${dest}")"
        return 0
      fi
      rm -f "${dest}.part"
      echo "[nominatim] Falló: ${url}"
    done
    echo "[nominatim] Reintento en 60 s..."
    sleep 60
    attempt=$((attempt + 1))
  done

  echo "[nominatim] ERROR: no se pudo descargar el PBF"
  return 1
}

prepare_pbf() {
  if [ -n "${PBF_PATH:-}" ] && [ -f "${PBF_PATH}" ]; then
    echo "[nominatim] Usando PBF local: ${PBF_PATH}"
    return
  fi

  if [ -f "${SALTA_PBF}" ]; then
    export PBF_PATH="${SALTA_PBF}"
    unset PBF_URL
    echo "[nominatim] Reutilizando ${SALTA_PBF}"
    return
  fi

  # URL explícita (Supabase, Release manual, etc.)
  if [ -n "${PBF_URL:-}" ]; then
    download_with_retries "${SALTA_PBF}" "${PBF_URL}"
    export PBF_PATH="${SALTA_PBF}"
    unset PBF_URL
    return
  fi

  # Release de GitHub: solo 1 intento (suele no existir si Actions está bloqueado).
  if [ -n "${GITHUB_SALTA_PBF_URL:-}" ]; then
  if try_once "${SALTA_PBF}" "${GITHUB_SALTA_PBF_URL}" 2>/dev/null; then
    export PBF_PATH="${SALTA_PBF}"
    unset PBF_URL
    echo "[nominatim] Usando Release de GitHub"
    return
  fi
  rm -f "${SALTA_PBF}"
  echo "[nominatim] Release de GitHub no disponible, usando mirrors..."
  fi

  # Argentina desde BBBike (Geofabrik bloqueado en Railway) + recorte Salta.
  local argentina="${DATA_DIR}/argentina.osm.pbf"
  download_with_retries "${argentina}" \
    "${MIRROR_BBBIKE}" \
    "${MIRROR_GEOFABRIK}"

  echo "[nominatim] Extrayendo Salta (bbox ${SALTA_BBOX})..."
  osmium extract -b "${SALTA_BBOX}" "${argentina}" -o "${SALTA_PBF}" --overwrite
  if [ "${KEEP_ARGENTINA_PBF:-false}" != "true" ]; then
    rm -f "${argentina}"
  fi
  export PBF_PATH="${SALTA_PBF}"
  unset PBF_URL
}

prepare_pbf

if [ -f /app/start.sh ]; then
  sed -i "s/--bind :8080/--bind :${LISTEN_PORT}/" /app/start.sh
fi

echo "[nominatim] PBF_PATH=${PBF_PATH:-}"
echo "[nominatim] API en puerto ${LISTEN_PORT}"
exec /app/start.sh
