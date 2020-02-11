import http.server
import re
import psycopg2

DATABASE = {
    'user':     'osmuk_user',
    'password': 'osmuk',
    'host':     'localhost',
    'port':     '5432',
    'database': 'osm-rutland'
    }

# SQL queries
BOUNDARIES = {
    'select':     'osm_id, name, admin_level',
    'from':       'planet_osm_roads',
    'where':      "boundary = 'administrative'",
    'geomColumn': 'way',
    'srid':       '3857'
    }

ROADS = {
    'select':     'osm_id, name, highway',
    'from':       'planet_osm_roads',
    'where':      "highway is not null",
    'geomColumn': 'way',
    'srid':       '3857'
    }

FOOD = {
    'select':     'osm_id, amenity, name',
    'from':       'planet_osm_point',
    'where':      "amenity in ('restaurant', 'fast_food', 'cafe', 'pub', 'bar', 'nightclub')",
    'geomColumn': 'way',
    'srid':       '3857'
    }

# HTTP server information
HOST = 'localhost'
PORT = 8080


########################################################################

class TileRequestHandler(http.server.BaseHTTPRequestHandler):

    DATABASE_CONNECTION = None

    # Search REQUEST_PATH for /{layer}/{z}/{x}/{y}.{format} patterns
    def to_tile(self, path):
        m = re.search(r'^\/(\w+)\/(\d+)\/(\d+)\/(\d+)\.(\w+)', path)
        if (m):
            return {'layer': m.group(1),
                    'zoom': int(m.group(2)),
                    'x': int(m.group(3)),
                    'y': int(m.group(4)),
                    'format': m.group(5)}
        else:
            return None

    # Do we have all keys we need?
    # Do the tile x/y coordinates make sense at this zoom level?
    def is_valid(self, tile):
        print(tile)
        if not ('x' in tile and 'y' in tile and 'zoom' in tile):
            return False
        if 'format' not in tile or tile['format'] not in ['pbf', 'mvt']:
            return False
        size = 2 ** tile['zoom']
        if tile['x'] >= size or tile['y'] >= size:
            return False
        if tile['x'] < 0 or tile['y'] < 0:
            return False
        return True

    # Calculate envelope in "Spherical Mercator" (https://epsg.io/3857)
    def to_envelope(self, tile):
        # Width of world in EPSG:3857
        worldMercMax = 20037508.3427892
        worldMercMin = -1 * worldMercMax
        worldMercSize = worldMercMax - worldMercMin
        # Width in tiles
        worldTileSize = 2 ** tile['zoom']
        # Tile width in EPSG:3857
        tileMercSize = worldMercSize / worldTileSize
        # Calculate geographic bounds from tile coordinates
        # XYZ tile coordinates are in "image space" so origin is
        # top-left, not bottom right
        envelope = dict()
        envelope['xmin'] = worldMercMin + tileMercSize * tile['x']
        envelope['xmax'] = worldMercMin + tileMercSize * (tile['x'] + 1)
        envelope['ymin'] = worldMercMax - tileMercSize * (tile['y'] + 1)
        envelope['ymax'] = worldMercMax - tileMercSize * (tile['y'])
        return envelope

    # Generate SQL to materialize a query envelope in EPSG:3857.
    # Densify the edges a little so the envelope can be
    # safely converted to other coordinate systems.
    def to_bounds_sql(self, envelope):
        DENSIFY_FACTOR = 4
        envelope['segSize'] = (envelope['xmax'] - envelope['xmin'])/DENSIFY_FACTOR
        template = 'ST_Segmentize( \
            ST_MakeEnvelope({xmin}, {ymin}, {xmax}, {ymax}, 3857),{segSize} \
        )'
        return template.format(**envelope)

    # Generate a SQL query to pull a tile worth of MVT data
    # from the table of interest.
    def to_sql(self, table, envelope):
        tbl = table.copy()
        tbl['envelope'] = self.to_bounds_sql(envelope)
        if tbl['where'] > '':
            tbl['and_where'] = "AND {}".format(tbl['where'])
        else:
            tbl['and_where'] = ''
        # Materialize the bounds
        # Select the relevant geometry and clip to MVT bounds
        # Convert to MVT format
        template = """
            WITH
            bounds AS (
                SELECT {envelope} AS geom,
                       {envelope}::box2d AS b2d
            ),
            mvtgeom AS (
                SELECT ST_AsMVTGeom(
                    ST_Transform(t.{geomColumn}, 3857),
                    bounds.b2d
                ) AS geom,
                       {select}
                FROM {from} t, bounds
                WHERE ST_Intersects(
                    t.{geomColumn},
                    ST_Transform(bounds.geom, {srid})
                )
                {and_where}
            )
            SELECT ST_AsMVT(mvtgeom.*, 'default') FROM mvtgeom
        """
        return template.format(**tbl)

    # Run tile query SQL and return error on failure conditions
    def to_pbf(self, sql):
        # Make and hold connection to database
        if not self.DATABASE_CONNECTION:
            try:
                self.DATABASE_CONNECTION = psycopg2.connect(**DATABASE)
            except (Exception, psycopg2.Error):
                self.send_error(500, "cannot connect: %s" % (str(DATABASE)))
                return None

        # Query for MVT
        with self.DATABASE_CONNECTION.cursor() as cur:
            cur.execute(sql)
            if not cur:
                self.send_error(404, "sql query failed: %s" % (sql))
                return None
            return cur.fetchone()[0]

        return None

    def select_table(self, tile):
        self.log_message("layer: %s" % (tile['layer']))
        if tile['layer'] == 'boundaries':
            return BOUNDARIES
        if tile['layer'] == 'roads':
            return ROADS
        if tile['layer'] == 'food':
            return FOOD
        return BOUNDARIES

    # Handle HTTP GET requests
    def do_GET(self):
        tile = self.to_tile(self.path)
        self.log_message("tile: %s" % (tile))
        if not (tile and self.is_valid(tile)):
            self.send_error(400, "invalid tile path: %s" % (self.path))
            return

        table = self.select_table(tile)
        envelope = self.to_envelope(tile)
        sql = self.to_sql(table, envelope)
        pbf = self.to_pbf(sql)

        self.log_message(
            "path: %s\ntile: %s\n envelope: %s" % (self.path, tile, envelope)
        )
        self.log_message("sql: %s" % (sql))

        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-type", "application/vnd.mapbox-vector-tile")
        self.end_headers()
        self.wfile.write(pbf)


with http.server.HTTPServer((HOST, PORT), TileRequestHandler) as server:
    try:
        print("serving at port", PORT)
        server.serve_forever()
    except KeyboardInterrupt:
        if self.DATABASE_CONNECTION:
            self.DATABASE_CONNECTION.close()
        print('^C received, shutting down server')
        server.socket.close()
