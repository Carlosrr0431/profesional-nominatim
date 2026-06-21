FROM mediagis/nominatim:5.3

RUN apt-get update \
  && apt-get install -y --no-install-recommends osmium-tool curl \
  && rm -rf /var/lib/apt/lists/*

ENV PORT=8080
ENV SALTA_EXTRACT=true
ENV IMPORT_WIKIPEDIA=false
ENV IMPORT_US_TIGER=false
ENV IMPORT_GB_POSTCODES=false
ENV FREEZE=true
ENV IMPORT_STYLE=full
ENV USER_AGENT=ProfesionalApp-Nominatim/1.0
ENV RAILWAY_RUN_UID=0
# POSTGRES_* y THREADS: los define entrypoint.sh según import vs runtime

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
