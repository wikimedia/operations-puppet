-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_water(bbox geometry, zoom_level integer)
    RETURNS TABLE(osm_id bigint, geometry geometry)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
  SELECT
    osm_id,
    way
  FROM
    planet_osm_polygon
  WHERE
    (
      "natural" = 'water'
      OR (waterway IS NOT NULL AND waterway <> '')
      OR landuse = 'reservoir'
      OR landuse = 'pond'
    )
    AND
    (
      zoom_level >= 14
      OR way_area >= 5000000000 / 2.3^zoom_level
    )
    AND way && bbox
  UNION ALL
  SELECT
    gid::bigint AS osm_id,
    way
  FROM
    water_polygons
  WHERE
    zoom_level >= 10
    AND way && bbox
  UNION ALL
  SELECT
    gid::bigint AS osm_id,
    way
  FROM
    water_polygons_simplified
  WHERE
    zoom_level < 10
    AND way && bbox
  ;
$BODY$;
