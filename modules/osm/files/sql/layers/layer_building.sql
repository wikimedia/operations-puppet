-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_building(bbox geometry, zoom_level integer)
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
    zoom_level >= 14
    AND
    	(building IS NOT NULL AND building <> '')
    AND
    	building <> 'no'
    AND
    	way && bbox
  ;
$BODY$;
