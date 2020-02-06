SELECT amenity, fhrs, sum(total) as sum_total
FROM 
(
	SELECT osm.amenity,
		CASE WHEN tags::hstore -> 'fhrs:id' IS NULL THEN false ELSE true END as fhrs, 
		count(*) as total
	FROM planet_osm_point osm
	WHERE osm.amenity IS NOT NULL
	GROUP BY osm.amenity, fhrs
UNION
	SELECT osm.amenity,
		CASE WHEN tags::hstore -> 'fhrs:id' IS NULL THEN false ELSE true END as fhrs, 
		count(*) as total
	FROM planet_osm_polygon osm
	WHERE osm.amenity IS NOT NULL
	GROUP BY osm.amenity, fhrs
) all_records
GROUP BY amenity, fhrs
ORDER BY sum_total desc;
