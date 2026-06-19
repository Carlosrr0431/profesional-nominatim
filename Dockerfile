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
ENV THREADS=1
ENV IMPORT_STYLE=full
ENV USER_AGENT=ProfesionalApp-Nominatim/1.0
ENV RAILWAY_RUN_UID=0

ENV POSTGRES_SHARED_BUFFERS=512MB
ENV POSTGRES_MAINTENANCE_WORK_MEM=1GB
ENV POSTGRES_AUTOVACUUM_WORK_MEM=256MB
ENV POSTGRES_WORK_MEM=32MB
ENV POSTGRES_EFFECTIVE_CACHE_SIZE=2GB

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
