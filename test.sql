with a as(
SELECT
	a.id as osm_id
, (st_Dump(a.geom)).path[1] as polygon_id
, st_simplify(st_transform(st_removeRepeatedPoints((st_Dump(a.geom)).geom),2154),.01) st_dump
, a.geom
FROM % a -- variable table batiment
WHERE a.id = % -- variable batiment id
)
, ilot_terrain_buildings as (
	SELECT
		a.geom
	FROM % a-- variable table batiment
	JOIN (
		SELECT
			ST_Union(geom) geom
		FROM % a -- variable parcelle table
		WHERE ilot_id = (
			SELECT 
				ilot_id
			FROM % a
			WHERE id = ''%'' -- variable main_terrain
		)
	) b
	ON ST_Intersects(a.geom, b.geom)
	WHERE id != % -- variable batiment id
)
, b AS (
-- get rings; 0 is exterior, > 0 are holes
SELECT
	osm_id
, CASE
		WHEN polygon_id is NULL THEN 0 else polygon_id
	END as polygon_id
, (st_DumpRings(st_dump)).path[1] as ring_id
, (st_DumpRings(st_dump)).geom::geometry(polygon,2154) st_ring 
FROM a
)
, c  AS (
-- dumpPoints returns ordered points from exterior Ring of footprints
SELECT
  osm_id
, polygon_id
, ring_id
, (st_DumpPoints(st_Ring)).geom::geometry(point,2154) 
, (st_DumpPoints(st_Ring)).path[2] 
FROM b
)
, d AS (
--segments from dumpPoints (1) 
SELECT
	osm_id
, polygon_id
, ring_id
,  ST_MakeLine(lag(geom, 1, NULL) 
							 OVER (
								 PARTITION BY osm_id, polygon_id, ring_id  
								 ORDER BY  osm_id, polygon_id, ring_id, path),
							 geom)::geometry(linestring,2154) 
FROM c
)
, e AS (
--segments from dumpPoints (2) are walls
SELECT
  osm_id
, polygon_id
, ring_id
, row_number() OVER (PARTITION BY osm_id ORDER BY osm_id, polygon_id) as edge_id
, st_ForceRHR(st_makeline)::geometry(linestring,2154) as st_edge
, st_transform(st_ForceRHR(st_makeline)::geometry(linestring,2154),4326) as wgs
FROM d WHERE st_makeline IS NOT NULL
)
-- Qualification of walls that are internal
, walls_qualification_internal_building as (
	SELECT
		*
	, CASE 
			WHEN ring_id > 0 THEN ''internal_building'' ELSE NULL 
		END as qualification
	FROM e
)
, tf AS (
-- touching footprints from a
SELECT
  a.osm_id
, a.polygon_id
, b.id as touches_id
, st_removeRepeatedPoints(st_transform(b.geom,2154)) as touches_geom
FROM a 
JOIN % b 
  ON  b.geom && a.geom AND st_touches(a.geom, b.geom)
ORDER BY osm_id, polygon_id, touches_id
)
, f AS (
SELECT 
	wqi.*
, tf.touches_id
, st_length(st_intersection(wqi.st_edge, tf.touches_geom))
FROM walls_qualification_internal_building wqi
JOIN tf 
	ON wqi.osm_id = tf.osm_id 
	AND st_intersects(tf.touches_geom, wqi.st_edge)
WHERE st_Geometrytype(st_intersection(wqi.st_edge, tf.touches_geom)) = ''ST_LineString''
	AND wqi.qualification IS NULL
)
, walls_qualification_adjacent AS (
SELECT
  wqi.osm_id
, wqi.polygon_id
, wqi.ring_id
, wqi.edge_id
, wqi.st_edge
, wqi.wgs
, CASE
		WHEN f.touches_id IS NOT NULL THEN ''party'' else wqi.qualification 
	END as qualification 
FROM walls_qualification_internal_building wqi
LEFT JOIN f 
  ON wqi.osm_id = f.osm_id 
 AND wqi.polygon_id = f.polygon_id
 AND wqi.edge_id = f.edge_id
ORDER BY osm_id, polygon_id, ring_id, edge_id
)
, g AS (
-- parallels for external walls
SELECT
	wqa.*
, st_forceRHR(st_offsetCurve(st_edge, 10)) as st_parallel 
FROM walls_qualification_adjacent wqa
WHERE qualification is null
	AND st_isvalid(st_edge) IS TRUE
)
, h AS (
-- azimuth
SELECT 
	g.*
, st_azimuth(st_centroid(st_edge),
						 st_centroid(st_parallel)) FROM g
WHERE st_length(st_edge)>=.1
)
, i AS (
-- perpendicular
SELECT
	osm_id
, polygon_id
, edge_id
, ring_id
, st_edge
, wgs
, qualification
, st_makeline(st_centroid(wgs),
							st_project(st_centroid(wgs), 
												 70, 
												 st_azimuth
												)::geometry(point,4326)
						 )::geometry(linestring,4326) as st_perpendicular
 FROM h
)
, walls_qualification_internal_building_2 AS (
-- perps that intersects buildings in terrain should get non-street walls
SELECT
	*
FROM (
		SELECT 
		i.osm_id
	, i.polygon_id
	, i.edge_id
	, ST_Transform(i.st_edge,4326) as wgs
	, i.ring_id
	, ''internal_batiment'' as qualification
	, ST_Length(ST_Union(ST_Intersection(i.st_perpendicular,geom_osm.geom))::geography) as intersection_length
	FROM i 
	JOIN a geom_osm
		ON st_intersects(i.st_perpendicular, geom_osm.geom)
	GROUP BY i.osm_id, i.polygon_id, i.ring_id, i.edge_id, ST_Transform(i.st_edge,4326)
) subquery
WHERE intersection_length > .1
)
, walls_qualification_internal_ilot_building AS (
SELECT 
	i.osm_id
, i.polygon_id
, i.edge_id
, ST_Transform(i.st_edge,4326) as wgs
, i.ring_id
, ''internal_ilot_building'' as qualification
FROM i
LEFT OUTER JOIN walls_qualification_internal_building_2 wqib2
on i.edge_id = wqib2.edge_id
JOIN ilot_terrain_buildings a
	ON st_intersects(i.st_perpendicular, a.geom)
WHERE wqib2.edge_id is null
GROUP BY i.osm_id, i.polygon_id, i.ring_id, i.edge_id, ST_Transform(i.st_edge,4326)
)
, segs AS (
SELECT
	*
FROM % -- segment tables
)
, k AS (
SELECT 
	i.osm_id
, i.polygon_id
, i.edge_id
, i.ring_id
, i.wgs
, i.st_edge
, st_centroid(i.st_edge)
, i.st_perpendicular 
, CASE
		WHEN j.qualification IS NOT NULL THEN j.qualification 
		WHEN i.qualification IS NOT NULL THEN i.qualification 
		WHEN wqib2.qualification IS NOT NULL THEN wqib2.qualification 
		ELSE NULL
	END as qualification
FROM i
LEFT JOIN walls_qualification_internal_ilot_building j
	ON i.osm_id= j.osm_id 
	AND i.polygon_id = j.polygon_id 
	AND i.ring_id = j.ring_id 
	AND i.edge_id = j.edge_id
LEFT JOIN walls_qualification_internal_building_2 wqib2
	ON i.osm_id= wqib2.osm_id 
	AND i.polygon_id = wqib2.polygon_id 
	AND i.ring_id = wqib2.ring_id 
	AND i.edge_id = wqib2.edge_id
)
, walls_qualification_street AS (
-- buffer size is critical
SELECT 
  k.edge_id
, k.wgs
, ''street'' as qualification
, segs.id as seg_id
, round(st_distance(st_transform(segs.geom,2154), st_centroid)::numeric,1 ) as rf -- recul facade par rapport au segment
FROM k 
JOIN segs
  ON st_intersects(st_perpendicular, segs.geom) 
  OR st_dwithin(k.st_centroid, st_transform(segs.geom,2154),1.4)
WHERE k.qualification IS NULL and segs.qualification = ''street''
)
, walls_qualification_internal_ilot_nothing AS (
	-- qualification of walls that are internat to ilot 
	-- and do not face closely any building
	-- This qualification is done by elimination
	-- After all the other qualification were done on the buildings walls
	SELECT
	  k.edge_id
	, k.wgs
	, ''internal_ilot_nothing'' AS qualification
	FROM k
	LEFT JOIN walls_qualification_street wqs
	ON k.edge_id = wqs.edge_id
	WHERE wqs.edge_id IS NULL AND k.qualification IS NULL
)
, walls_qualified as (
SELECT
  edge_id as id
, wgs as geom
, qualification
, NULL::integer as seg_id
, NULL::integer as rf
FROM walls_qualification_internal_building
WHERE qualification IS NOT NULL
UNION
SELECT
  edge_id as id
, wgs as geom
, qualification
, NULL::integer as seg_id
, NULL::integer as rf
FROM walls_qualification_adjacent
WHERE qualification is not null
UNION
SELECT
  edge_id as id
, wgs as geom
, qualification
, NULL::integer as seg_id
, NULL::integer as rf
FROM walls_qualification_internal_building_2
WHERE qualification IS NOT NULL
UNION
SELECT
  edge_id as id
, wgs as geom
, qualification
, NULL::integer as seg_id
, NULL::integer as rf
FROM walls_qualification_internal_ilot_building
WHERE qualification IS NOT NULL
UNION
SELECT
  edge_id as id
, wgs as geom
, qualification
, NULL::integer as seg_id
, NULL::integer as rf
FROM walls_qualification_internal_ilot_nothing
WHERE qualification IS NOT NULL
UNION
SELECT
  edge_id as id
, wgs as geom
, qualification
, seg_id
, rf
FROM walls_qualification_street
)
SELECT
 	id
, geom
, round(ST_Length(geom::geography)::numeric,2) as length
, qualification
, seg_id
, rf
FROM walls_qualified
'
, building_osm_table
, building_osm_id
, building_osm_table
, parcelle_cadastre_table
, parcelle_cadastre_table
, terrain_main_id
, building_osm_id
, building_osm_table
, parcelle_limits_table
