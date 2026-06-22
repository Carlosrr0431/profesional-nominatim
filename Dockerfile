FROM mediagis/nominatim:5.3

RUN apt-get update \
  && apt-get install -y --no-install-recommends osmium-tool curl \
  && rm -rf /var/lib/apt/lists/*

ENV PORT=8080
ENV IMPORT_REGION=salta
ENV SALTA_EXTRACT=true
ENV SALTA_BBOX=-68.75,-26.62,-62.00,-21.78
ENV CAPITAL_BBOX=-65.55,-24.90,-65.30,-24.70
ENV IMPORT_WIKIPEDIA=false
ENV IMPORT_US_TIGER=false
ENV IMPORT_GB_POSTCODES=false
ENV FREEZE=true
ENV WARMUP_ON_STARTUP=false
# address = calles y alturas (POIs los resuelve Google Places en el dashboard)
ENV IMPORT_STYLE=address
ENV USER_AGENT=ProfesionalApp-Nominatim/1.0
ENV RAILWAY_RUN_UID=0
ENV GUNICORN_WORKERS=1
# POSTGRES_*: los fija entrypoint.sh (no poner defaults altos acá)

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
