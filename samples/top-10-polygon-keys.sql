-- note that way_area is added to every polygon when imported

SELECT count(*) as c, (each(tags)).key as k
FROM planet_osm_polygon
GROUP BY k
ORDER BY c desc
LIMIT 10;
