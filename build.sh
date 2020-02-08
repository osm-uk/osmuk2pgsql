# prerequisite: install postgresql, postgis, osm2pgsql (on Mac OS X take a look at https://github.com/OSGeo/homebrew-osgeo4mac)
# basics: wget and unzip
createdb osmuk
psql -d osmuk -c "create extension postgis;"
psql -d osmuk -c "create extension hstore;"

wget https://github.com/gravitystorm/openstreetmap-carto/archive/master.zip
unzip master.zip
rm master.zip

# Geofabrik British Isles includes IoM, Channel Islands,,,and Eire
# this will take some time.....
wget https://download.geofabrik.de/europe/british-isles-latest.osm.pbf
#checksum 1497fd293ad2a70c257b7d78cf7e4683

osm2pgsql --create --slim \
    --cache 1000 --number-processes 2 --hstore-all \
    --style openstreetmap-carto-master/openstreetmap-carto.style --multi-geometry \
    -d osmuk british-isles-latest.osm.pbf

# Some indexes to speed things up
psql -d osmuk -c "CREATE INDEX planet_osm_point_amenity
    ON public.planet_osm_point USING btree
    (amenity ASC NULLS LAST)
    INCLUDE(amenity)
    TABLESPACE pg_default;"

psql -d osmuk -c "CREATE INDEX planet_osm_point_shop
    ON public.planet_osm_point USING btree
    (shop ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d osmuk -c "CREATE INDEX planet_osm_polygon_amenity
    ON public.planet_osm_polygon USING btree
    (amenity ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d osmuk -c "CREATE INDEX planet_osm_polygon_shop
    ON public.planet_osm_polygon USING btree
    (shop ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d osmuk -c "CREATE INDEX planet_osm_point_name
    ON public.planet_osm_point USING btree
    (name text_pattern_ops ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d osmuk -c "CREATE INDEX planet_osm_polygon_name
    ON public.planet_osm_polygon USING btree
    (name text_pattern_ops ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d osmuk -c "CREATE INDEX planet_osm_point_geom
    ON public.planet_osm_point USING gist
    (way)
    TABLESPACE pg_default;"

psql -d osmuk -c "CREATE INDEX planet_osm_polygon_geom
    ON public.planet_osm_polygon USING gist
    (way)
    TABLESPACE pg_default;"

# SQL to remove Eire
psql -d osmuk -c "DELETE
FROM public.planet_osm_point
WHERE osm_id in
(
	SELECT osm.osm_id
	FROM public.planet_osm_point osm
	JOIN public.planet_osm_polygon eire on eire.osm_id='-62273'
	WHERE st_within(osm.way, eire.way)
);"

psql -d osmuk -c "DELETE
FROM public.planet_osm_polygon
WHERE osm_id in
(
	SELECT osm.osm_id
	FROM public.planet_osm_polygon osm
	JOIN public.planet_osm_polygon eire on eire.osm_id='-62273'
	WHERE st_within(osm.way, eire.way)
);"

psql -d osmuk -c "DELETE
FROM public.planet_osm_roads
WHERE osm_id in
(
	SELECT osm.osm_id
	FROM public.planet_osm_polygon osm
	JOIN public.planet_osm_polygon eire on eire.osm_id='-62273'
	WHERE st_within(osm.way, eire.way)
);"
