-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_waterway(bbox geometry, zoom_level integer)
    RETURNS TABLE(osm_id bigint, geometry geometry, class text)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
  SELECT 
    osm_id, 
    way, 
    waterway AS class
  FROM 
    planet_osm_line
  WHERE
    (
      (
        waterway IN ('river', 'canal')
        AND zoom_level >= 8
      )
      OR
      (
        waterway IN ('stream', 'stream_intermittent')
        AND zoom_level >= 13
      )
    )
    AND way && bbox
  ;
$BODY$;
