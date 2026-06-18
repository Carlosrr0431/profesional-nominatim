#!/bin/bash
set -euo pipefail

LISTEN_PORT="${PORT:-8080}"
DATA_DIR="/nominatim/data"
SALTA_PBF="${DATA_DIR}/salta.osm.pbf"
SALTA_BBOX="${SALTA_BBOX:--68.75,-26.62,-62.00,-21.78}"
USER_AGENT="${USER_AGENT:-ProfesionalApp-Nominatim/1.0 (contacto@profesional.app)}"

# Mirrors (Geofabrik suele estar bloqueado desde Railway).
MIRROR_BBBIKE="https://download3.bbbike.org/osm/pbf/region/south-america/argentina.osm.pbf"
MIRROR_GEOFABRIK="https://download.geofabrik.de/south-america/argentina-latest.osm.pbf"
MIRROR_GITHUB_RELEASE="${DEFAULT_SALTA_PBF_URL:-https://github.com/Carlosrr0431/profesional-nominatim/releases/download/salta-data-v1/salta.osm.pbf}"

echo "[nominatim] === Arranque $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
free -h 2>/dev/null || true
df -h / /var/lib/postgresql/16/main /nominatim 2>/dev/null || df -h

mkdir -p "${DATA_DIR}"

download_file() {
  local dest="$1"
  shift
  local url attempt=1

  while [ "$attempt" -le 20 ]; do
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
    echo "[nominatim] Reintento en 90 s..."
    sleep 90
    attempt=$((attempt + 1))
  done

  echo "[nominatim] ERROR: no se pudo descargar el PBF desde ningún mirror"
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

  # URL directa al .pbf final (Supabase, GitHub Release, etc.)
  if [ -n "${PBF_URL:-}" ]; then
    download_file "${SALTA_PBF}" "${PBF_URL}"
    export PBF_PATH="${SALTA_PBF}"
    unset PBF_URL
    return
  fi

  # 1) Release de GitHub (si existe salta.osm.pbf)
  if download_file "${SALTA_PBF}" "${MIRROR_GITHUB_RELEASE}" 2>/dev/null; then
    export PBF_PATH="${SALTA_PBF}"
    unset PBF_URL
    return
  fi
  rm -f "${SALTA_PBF}"

  # 2) Argentina desde BBBike u otros + recorte Salta
  local argentina="${DATA_DIR}/argentina.osm.pbf"
  download_file "${argentina}" \
    "${MIRROR_BBBIKE}" \
    "${MIRROR_GEOFABRIK}" \
    "${PBF_SOURCE_URL:-}"

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
