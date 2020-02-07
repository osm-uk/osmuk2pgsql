# OSMUK-in-a-box
Build a postgresql+postgis database of OpenStreetMap for the areas covered by OSMUK (the United Kingdom including Northern Ireland, the Isle of Man and Channel Islands). For use in hackdays, personal projects, professional projects, etc.

## aim
A quick and easy way for someone with some technical skills but limited experience of OSM to set up a UK database for hacking with. Self-contained and operating system independent.

## rationale
When asked,
> "What Open Data is there in the UK that could be used in a hackday?"

I like to reply,

> "The richest source of geospatial data is OpenStreetMap"

> "Great! How do I set that up?"

> "Easy! Just download the latest country file and load it into postgres using one of the OSM tools... Oh, and then ignore Eire. And put some indexes on it or it'll be slow."

> "The wha?...(Thanks, but I probably won't bother)"

## architecture
The first version is a bash shell script. As a prerequisite it requires postgresl, postgis, hstore, osm2pgsql, and wget to be installed. The script could install stuff for you but it gets complicated coping with Linux, Windows, Mac OS X, etc.

Second version will most likely use Docker.

## alternatives
OSM data can be explored quite quickly using country-specific Taginfo pages from Geofabrik:

* http://taginfo.geofabrik.de/europe/great-britain/
* http://taginfo.geofabrik.de/europe/great-britain/england/
* http://taginfo.geofabrik.de/europe/great-britain/england/greater-manchester/
* etc.
* http://taginfo.geofabrik.de/europe/great-britain/scotland/
* http://taginfo.geofabrik.de/europe/great-britain/wales/

https://overpass-turbo.eu/ allows for more complicated queries but can become overloaded if you ask for the whole country

## Vector tile server
Based on Paul Ramsey's https://github.com/pramsey/minimal-mvt this is a minimal vector tile server

```sh
virtualenv --python python3 venv
source venv/bin/activate
pip install -r requirements.txt
```

Run with
```sh
python3 minimal-mvt.py
```

![Screenshot of Mapbox GL Example](mapbox-gl.png)
