FROM mediagis/nominatim:5.3

RUN apt-get update \
  && apt-get install -y --no-install-recommends osmium-tool \
  && rm -rf /var/lib/apt/lists/*

ENV PORT=8080
ENV SALTA_EXTRACT=true
ENV SALTA_BBOX=-68.75,-26.62,-62.00,-21.78
ENV PBF_SOURCE_URL=https://download.geofabrik.de/south-america/argentina-latest.osm.pbf
ENV IMPORT_WIKIPEDIA=false
ENV IMPORT_US_TIGER=false
ENV IMPORT_GB_POSTCODES=false
ENV FREEZE=true
ENV THREADS=1
ENV USER_AGENT=ProfesionalApp-Nominatim/1.0
# Evita errores de permisos al escribir en el volumen de Railway.
ENV RAILWAY_RUN_UID=0

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
