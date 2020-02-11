FROM postgres:12 as deploy

RUN apt-get update && apt-get upgrade --yes && apt-get --yes install osm2pgsql postgresql-12-postgis-3 wget python3


# COPY dist/setup_db.sql /docker-entrypoint-initdb.d/01_setup.sql
# COPY dist/load_data.sh /docker-entrypoint-initdb.d/02_load_data.sh
# COPY dist/add_grants.sql /docker-entrypoint-initdb.d/03_add_grants.sql