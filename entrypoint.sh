#!/bin/bash
set -euo pipefail

LISTEN_PORT="${PORT:-8080}"
DATA_DIR="/nominatim/data"
SALTA_PBF="${DATA_DIR}/salta.osm.pbf"
PBF_SOURCE_URL="${PBF_SOURCE_URL:-https://download.geofabrik.de/south-america/argentina-latest.osm.pbf}"
SALTA_BBOX="${SALTA_BBOX:--68.75,-26.62,-62.00,-21.78}"
USER_AGENT="${USER_AGENT:-ProfesionalApp-Nominatim/1.0}"

echo "[nominatim] === Arranque $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "[nominatim] Memoria:"; free -h 2>/dev/null || true
echo "[nominatim] Disco:"; df -h / /var/lib/postgresql/16/main /nominatim 2>/dev/null || df -h

mkdir -p "${DATA_DIR}"

prepare_pbf() {
  if [ -n "${PBF_PATH:-}" ] && [ -f "${PBF_PATH}" ]; then
    echo "[nominatim] Usando PBF local: ${PBF_PATH}"
    return
  fi

  if [ -n "${PBF_URL:-}" ]; then
    echo "[nominatim] PBF_URL definido, lo usará init.sh"
    return
  fi

  if [ -f "${SALTA_PBF}" ]; then
    export PBF_PATH="${SALTA_PBF}"
    unset PBF_URL
    echo "[nominatim] Reutilizando ${SALTA_PBF}"
    return
  fi

  if [ "${SALTA_EXTRACT:-true}" = "true" ]; then
    local argentina="${DATA_DIR}/argentina-latest.osm.pbf"
    if [ ! -f "${argentina}" ]; then
      echo "[nominatim] Descargando Argentina desde Geofabrik..."
      curl -fsSL -A "${USER_AGENT}" -o "${argentina}" "${PBF_SOURCE_URL}"
    fi
    echo "[nominatim] Extrayendo provincia de Salta (bbox ${SALTA_BBOX})..."
    osmium extract -b "${SALTA_BBOX}" "${argentina}" -o "${SALTA_PBF}" --overwrite
    if [ "${KEEP_ARGENTINA_PBF:-false}" != "true" ]; then
      rm -f "${argentina}"
    fi
    export PBF_PATH="${SALTA_PBF}"
    unset PBF_URL
    return
  fi

  export PBF_URL="${PBF_SOURCE_URL}"
}

prepare_pbf

if [ -f /app/start.sh ]; then
  sed -i "s/--bind :8080/--bind :${LISTEN_PORT}/" /app/start.sh
fi

echo "[nominatim] PBF_PATH=${PBF_PATH:-} PBF_URL=${PBF_URL:-}"
echo "[nominatim] API en puerto ${LISTEN_PORT} — import puede tardar 1-3 h"
exec /app/start.sh
