-- show all shops with 'Tesco' in their name with their shop type

SELECT name, shop, sum(total) as sum_total
FROM 
(
	SELECT name, osm.shop, count(*) as total
	FROM planet_osm_point osm
	WHERE name like '%Tesco%'
	GROUP BY osm.shop, name
UNION
	SELECT name, osm.shop, count(*) as total
	FROM planet_osm_polygon osm
	WHERE name like '%Tesco%'
	GROUP BY osm.shop, name
) all_records
GROUP BY name, shop
ORDER BY sum_total desc;
