SELECT osm_id, tags->'name' as name, round(st_length(way)) / 1000 as km, tags
FROM planet_osm_line
WHERE tags->'route' = 'hiking'
ORDER BY km desc
LIMIT 10;
