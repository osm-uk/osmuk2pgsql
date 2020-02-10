# prerequisite: install postgresql, postgis, osm2pgsql (on Mac OS X take a look at https://github.com/OSGeo/homebrew-osgeo4mac)
# basics: wget and unzip

# Pick a Geofabrik download. Choices reflect what https://download.geofabrik.de/europe/great-britain.html offers
PS3='Please enter your choice: '
options=("uk"
"england" "scotland" "wales"
"bedfordshire"
"berkshire"
"bristol"
"buckinghamshire"
"cambridgeshire"
"cheshire" 
"cornwall"
"cumbria"
"derbyshire"
"devon"
"dorset"
"durham"
"east-sussex"
"east-yorkshire-with-hull"
"essex"
"gloucestershire"
"greater-london"
"greater-manchester"
"hampshire"
"herefordshire"
"hertfordshire"
"isle-of-wight"
"kent"
"lancashire"
"leicestershire"
"lincolnshire"
"merseyside"
"norfolk"
"north-yorkshire"
"northamptonshire"
"northumberland"
"nottinghamshire"
"oxfordshire"
"rutland"
"shropshire"
"somerset"
"south-yorkshire"
"staffordshire"
"suffolk"
"surrey"
"tyne-and-wear"
"warwickshire"
"west-midlands"
"west-sussex"
"west-yorkshire"
"wiltshire"
"worcestershire")
select opt in "${options[@]}"
do
    AREA=$opt
    break
done

DBNAME="osm-${AREA}"

psql -c "create role osmuk_user LOGIN PASSWORD 'osmuk';"
createdb $DBNAME -O osmuk_user
psql -d $DBNAME -c "create extension if not exists postgis;"
psql -d $DBNAME -c "create extension if not exists hstore;"

if [ ! -f openstreetmap-carto-master/openstreetmap-carto.style ]; then
    wget https://github.com/gravitystorm/openstreetmap-carto/archive/master.zip
    unzip master.zip
    rm master.zip
fi

if [ $AREA == "uk" ]; then
    ROOT="europe/"
    EXTRACT="britain-and-ireland"
elif [ $AREA == "england" ] || [ $AREA == "scotland" ] || [ $AREA == "wales" ]; then
    ROOT="europe/great-britain/"
    EXTRACT=$AREA
elif [ $AREA != "uk" ]; then
    ROOT="europe/great-britain/england/"
    EXTRACT=$AREA
fi

wget "http://download.geofabrik.de/${ROOT}${EXTRACT}-latest.osm.pbf"

osm2pgsql \
    --create \
    --slim \
    --cache 1000 \
    --number-processes 2 \
    --hstore-all \
    --multi-geometry \
    --style openstreetmap-carto-master/openstreetmap-carto.style \
    --tag-transform-script openstreetmap-carto-master/openstreetmap-carto.lua \
    --database $DBNAME "${EXTRACT}-latest.osm.pbf"

# Some indexes to speed things up
psql -d $DBNAME -c "CREATE INDEX planet_osm_point_amenity
    ON public.planet_osm_point USING btree
    (amenity ASC NULLS LAST)
    INCLUDE(amenity)
    TABLESPACE pg_default;"

psql -d $DBNAME -c "CREATE INDEX planet_osm_point_shop
    ON public.planet_osm_point USING btree
    (shop ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d $DBNAME -c "CREATE INDEX planet_osm_polygon_amenity
    ON public.planet_osm_polygon USING btree
    (amenity ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d $DBNAME -c "CREATE INDEX planet_osm_polygon_shop
    ON public.planet_osm_polygon USING btree
    (shop ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d $DBNAME -c "CREATE INDEX planet_osm_point_name
    ON public.planet_osm_point USING btree
    (name text_pattern_ops ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d $DBNAME -c "CREATE INDEX planet_osm_polygon_name
    ON public.planet_osm_polygon USING btree
    (name text_pattern_ops ASC NULLS LAST)
    TABLESPACE pg_default;"

psql -d $DBNAME -c "CREATE INDEX planet_osm_point_geom
    ON public.planet_osm_point USING gist
    (way)
    TABLESPACE pg_default;"

psql -d $DBNAME -c "CREATE INDEX planet_osm_polygon_geom
    ON public.planet_osm_polygon USING gist
    (way)
    TABLESPACE pg_default;"

# SQL to remove Eire
psql -d $DBNAME -c "DELETE
FROM public.planet_osm_point
WHERE osm_id in
(
	SELECT osm.osm_id
	FROM public.planet_osm_point osm
	JOIN public.planet_osm_polygon eire on eire.osm_id='-62273'
	WHERE st_within(osm.way, eire.way)
);"

psql -d $DBNAME -c "DELETE
FROM public.planet_osm_polygon
WHERE osm_id in
(
	SELECT osm.osm_id
	FROM public.planet_osm_polygon osm
	JOIN public.planet_osm_polygon eire on eire.osm_id='-62273'
	WHERE st_within(osm.way, eire.way)
);"

psql -d $DBNAME -c "DELETE
FROM public.planet_osm_roads
WHERE osm_id in
(
	SELECT osm.osm_id
	FROM public.planet_osm_polygon osm
	JOIN public.planet_osm_polygon eire on eire.osm_id='-62273'
	WHERE st_within(osm.way, eire.way)
);"

## configure and run vector tile server
psql -d $DBNAME -c "grant select on all tables in schema public to osmuk_user;"
sed -iE "s/'database': 'osm-[a-z/-]*'/'database': '${DBNAME}'/g" minimal-mvt.py
python3 minimal-mvt.py