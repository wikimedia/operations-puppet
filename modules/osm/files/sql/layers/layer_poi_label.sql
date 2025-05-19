-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_poi_label(bbox geometry, zoom_level integer)
    RETURNS TABLE(osm_id bigint, geometry geometry, name text, scalerank integer, localrank integer, maki text)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

  WITH maki_ranks(class, rank) AS (
    VALUES
      ('rail', 1),
      ('rail-metro', 1),
      ('rail-light', 1),
      ('ferry', 1),
      ('bus', 3)
  )

  SELECT 
    osm_id,
    way1,
    name,
    rank AS scalerank, 
    localrank,
    maki
  FROM
    (
      SELECT
        osm_id,
        name,
        (hstore_to_json(extract_names(tags)))::text name_,
        CASE
          WHEN railway = 'station' THEN 'rail'
          WHEN (tags->'subway') IS NOT NULL THEN 'rail-metro'
          WHEN highway = 'bus_stop' THEN 'bus'
          WHEN railway = 'tram_stop' THEN 'rail-light'
          WHEN amenity = 'ferry_terminal' THEN 'ferry'
          ELSE bail_out('Cannot classify poi_label, osm_id=%s', osm_id::TEXT)
        END AS maki,
        1 AS localrank,
        way AS way1
      FROM 
        planet_osm_point
      WHERE
        zoom_level >= 14
        AND
          (
            (public_transport='stop_position' AND (tags->'subway') IS NOT NULL)
            OR railway IN ('station', 'tram_stop')
            OR highway = 'bus_stop'
            OR amenity = 'ferry_terminal'
          )
        AND way && bbox
    UNION ALL
      SELECT
        osm_id,
        name,
        (hstore_to_json(extract_names(tags)))::text name_,
        CASE
          WHEN railway = 'station' THEN 'rail'
          WHEN (tags->'subway') IS NOT NULL THEN 'rail-metro'
          WHEN highway = 'bus_stop' THEN 'bus'
          WHEN railway = 'tram_stop' THEN 'rail-light'
          WHEN amenity = 'ferry_terminal' THEN 'ferry'
          ELSE bail_out('Cannot classify poi_label, osm_id=%s', osm_id::TEXT)
        END AS maki,
        1 AS localrank,
        ST_Centroid(way) AS way1
      FROM 
        planet_osm_polygon
      WHERE
        zoom_level >= 14
        AND
          (
            (public_transport='stop_position' AND (tags->'subway') IS NOT NULL)
            OR railway IN ('station', 'tram_stop')
            OR highway = 'bus_stop'
            OR amenity = 'ferry_terminal'
          )
        AND way && bbox
    ) AS data 
    JOIN 
      maki_ranks ON class=maki
    ORDER BY 
      scalerank, maki DESC, osm_id
    ;

$BODY$;
