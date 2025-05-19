-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_aeroway(bbox geometry, zoom_level integer)
    RETURNS TABLE(osm_id bigint, geometry geometry, type text)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
  SELECT 
    osm_id, 
    way, 
    aeroway AS type
  FROM 
    planet_osm_polygon
  WHERE
    (aeroway IS NOT NULL AND aeroway <> '')
    AND aeroway IN ('apron', 'helipad', 'runway', 'taxiway')
    AND zoom_level >= 12
    AND way && bbox
  UNION ALL
  SELECT 
    osm_id, 
    way, 
    aeroway AS type
  FROM 
    planet_osm_line
  WHERE
    (aeroway IS NOT NULL AND aeroway <> '')
    AND zoom_level >= 12
    AND way && bbox
  ;
$BODY$;
