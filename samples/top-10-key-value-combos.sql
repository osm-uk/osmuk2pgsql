SELECT count(*) as c, each(tags) as k
FROM planet_osm_polygon
GROUP BY k
ORDER BY c desc
LIMIT 10;
