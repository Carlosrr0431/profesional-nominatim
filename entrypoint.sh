#!/bin/bash
set -euo pipefail

LISTEN_PORT="${PORT:-8080}"
DATA_DIR="/nominatim/data"
SALTA_PBF="${DATA_DIR}/salta.osm.pbf"
SALTA_BBOX="${SALTA_BBOX:--68.75,-26.62,-62.00,-21.78}"
USER_AGENT="${USER_AGENT:-ProfesionalApp-Nominatim/1.0}"
DEFAULT_SALTA_PBF_URL="${DEFAULT_SALTA_PBF_URL:-https://github.com/Carlosrr0431/profesional-nominatim/releases/download/salta-data-v1/salta.osm.pbf}"
PBF_SOURCE_URL="${PBF_SOURCE_URL:-https://download.geofabrik.de/south-america/argentina-latest.osm.pbf}"

echo "[nominatim] === Arranque $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
free -h 2>/dev/null || true
df -h / /var/lib/postgresql/16/main /nominatim 2>/dev/null || df -h

mkdir -p "${DATA_DIR}"

download_file() {
  local dest="$1"
  shift
  local url attempt=1

  while [ "$attempt" -le 30 ]; do
    for url in "$@"; do
      [ -z "$url" ] && continue
      echo "[nominatim] Descarga intento ${attempt}: ${url}"
      if curl -fsSL -A "${USER_AGENT}" --connect-timeout 45 --max-time 7200 -C - -o "${dest}.part" "${url}"; then
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

  if [ -n "${PBF_URL:-}" ]; then
    download_file "${SALTA_PBF}" "${PBF_URL}"
    export PBF_PATH="${SALTA_PBF}"
    unset PBF_URL
    return
  fi

  if [ "${SALTA_EXTRACT:-false}" != "true" ]; then
    download_file "${SALTA_PBF}" "${DEFAULT_SALTA_PBF_URL}"
    export PBF_PATH="${SALTA_PBF}"
    unset PBF_URL
    return
  fi

  local argentina="${DATA_DIR}/argentina-latest.osm.pbf"
  download_file "${argentina}" \
    "${PBF_SOURCE_URL}" \
    "https://download3.bbbike.org/osm/pbf/region/south-america/argentina.osm.pbf"
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

echo "[nominatim] PBF_PATH=${PBF_PATH:-} PBF_URL=${PBF_URL:-}"
echo "[nominatim] API en puerto ${LISTEN_PORT}"
exec /app/start.sh
