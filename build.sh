# prerequisite: install postgresql, postgis, osm2pgsql (on Mac OS X take a look at https://github.com/OSGeo/homebrew-osgeo4mac)
# basics: wget and unzip

CENTRE="[-4.0, 54.1]"
# Pick a Geofabrik download. Choices reflect what https://download.geofabrik.de/europe/great-britain.html offers
PS3='Please enter your choice: '
options=(
    "uk"
    "england"
    "scotland"
    "wales"
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
    "worcestershire"
)
select opt in "${options[@]}"
do
    AREA=$opt
    case $opt in
        "uk")
            ;;
        "england")
            CENTRE="[-1.48, 52.36]"
            ;;
        "scotland")
            CENTRE="[-3.95, 56.13]"
            ;;
        "wales")
            CENTRE="[-3.68, 52.30]"
            ;;
        "bedfordshire")
            CENTRE="[-0.67, 52.11]"
            ;;
        "berkshire")
            CENTRE="[-1.06, 51.37]"
            ;;
        "bristol")
            CENTRE="[-2.58, 51.45]"
            ;;
        "buckinghamshire")
            CENTRE="[-0.81, 51.78]"
            ;;
        "cambridgeshire")
            CENTRE="[0.05. 52.32]"
            ;;
        "cheshire")
            CENTRE="[-2.81, 53.30]"
            ;;
        "cornwall")
            CENTRE="[-4.83, 50.42]"
            ;;
        "cumbria")
            CENTRE="[-2.89, 54.57]"
            ;;
        "derbyshire")
            CENTRE="[-1.57, 53.09]"
            ;;
        "devon")
            CENTRE="[-3.80, 50.73]"
            ;;
        "dorset")
            CENTRE="[-2.33, 50.82]"
            ;;
        "durham")
            CENTRE="[-1.58, 54.77]"
            ;;
        "east-sussex")
            CENTRE="[0.31, 50.92]"
            ;;
        "east-yorkshire-with-hull")
            CENTRE="[-0.43, 53.88]"
            ;;
        "essex")
            CENTRE="[0.55, 51.77]"
            ;;
        "gloucestershire")
            CENTRE="[-2.13, 51.80]"
            ;;
        "greater-london")
            CENTRE="[-0.10, 51.49]"
            ;;
        "greater-manchester")
            CENTRE="[-2.33, 53.51]"
            ;;
        "hampshire")
            CENTRE="[-1.34, 51.04]"
            ;;
        "herefordshire")
            CENTRE="[-2.78, 52.10]"
            ;;
        "hertfordshire")
            CENTRE="[-0.22, 51.80]"
            ;;
        "isle-of-wight")
            CENTRE="[-1.31, 50.67]"
            ;;
        "kent")
            CENTRE="[0.78, 51.17]"
            ;;
        "lancashire")
            CENTRE="[-2.62, 53.82]"
            ;;
        "leicestershire")
            CENTRE="[-1.13, 52.66]"
            ;;
        "lincolnshire")
            CENTRE="[-0.22, 53.08]"
            ;;
        "merseyside")
            CENTRE="[-2.91, 53.42]"
            ;;
        "norfolk")
            CENTRE="[0.91, 52.66]"
            ;;
        "north-yorkshire")
            CENTRE="[-1.50, 54.20]"
            ;;
        "northamptonshire")
            CENTRE="[-0.90, 52.28]"
            ;;
        "northumberland")
            CENTRE="[-2.09, 55.26]"
            ;;
        "nottinghamshire")
            CENTRE="[-0.98, 53.12]"
            ;;
        "oxfordshire")
            CENTRE="[-1.31, 51.75]"
            ;;
        "rutland")
            CENTRE="[-0.64, 52.64]"
            ;;
        "shropshire")
            CENTRE="[-2.69, 52.66]"
            ;;
        "somerset")
            CENTRE="[-3.06, 51.09]"
            ;;
        "south-yorkshire")
            CENTRE="[-1.34, 53.48]"
            ;;
        "staffordshire")
            CENTRE="[-2.04, 52.80]"
            ;;
        "suffolk")
            CENTRE="[1.07, 52.16]"
            ;;
        "surrey")
            CENTRE="[-0.42, 51.24]"
            ;;
        "tyne-and-wear")
            CENTRE="[-1.57, 54.95]"
            ;;
        "warwickshire")
            CENTRE="[-1.56, 52.28]"
            ;;
        "west-midlands")
            CENTRE="[-1.95, 52.48]"
            ;;
        "west-sussex")
            CENTRE="[-1.5, 50.7]"
            ;;
        "west-yorkshire")
            CENTRE="[-1.73, 53.73]"
            ;;
        "wiltshire")
            CENTRE="[-1.94, 51.27]"
            ;;
        "worcestershire")
            CENTRE="[-2.14, 52.19]"
            ;;
    esac
    break
done

DBNAME="osm-${AREA}"

psql -c "create role osmuk_user LOGIN PASSWORD 'osmuk';"
createdb -O osmuk_user $DBNAME
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
psql -d $DBNAME -c "
DELETE
FROM public.planet_osm_point
WHERE osm_id in
(
	SELECT osm.osm_id
	FROM public.planet_osm_point osm
	JOIN public.planet_osm_polygon eire on eire.osm_id='-62273'
	WHERE st_within(osm.way, eire.way)
);
"

psql -d $DBNAME -c "
DELETE
FROM public.planet_osm_polygon
WHERE osm_id in
(
	SELECT osm.osm_id
	FROM public.planet_osm_polygon osm
	JOIN public.planet_osm_polygon eire on eire.osm_id='-62273'
	WHERE st_within(osm.way, eire.way)
);
"

psql -d $DBNAME -c "
DELETE
FROM public.planet_osm_roads
WHERE osm_id in
(
	SELECT osm.osm_id
	FROM public.planet_osm_polygon osm
	JOIN public.planet_osm_polygon eire on eire.osm_id='-62273'
	WHERE st_within(osm.way, eire.way)
);
"

## configure and run vector tile server
psql -d $DBNAME -c "grant select on all tables in schema public to osmuk_user;"
sed -iE "s/'database': 'osm-[a-z/-]*'/'database': '${DBNAME}'/g" minimal-mvt.py
sed -iE "s/'center': .*$/'center': ${CENTRE},/g" map-mapboxgl/index.html

python3 minimal-mvt.py
