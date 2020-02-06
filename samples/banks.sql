SELECT name, sum(total) as sum_total
FROM 
(
	SELECT osm.name, count(*) as total
	FROM planet_osm_point osm
	WHERE osm.amenity='bank'
	GROUP BY osm.name
 union
	SELECT osm.name, count(*) as total
	FROM planet_osm_polygon osm
	WHERE osm.amenity='bank'
	GROUP BY osm.name
) all_records
GROUP BY name
ORDER BY sum_total desc;
