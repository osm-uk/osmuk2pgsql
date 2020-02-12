FROM kartoza/postgis:12.0 as osmuk_in_a_box

RUN apt-get update && apt-get upgrade --yes && apt-get --yes install osm2pgsql unzip wget

COPY build.sh /docker-entrypoint-initdb.d/build.sh