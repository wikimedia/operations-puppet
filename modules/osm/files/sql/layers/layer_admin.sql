-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_admin(bbox geometry, zoom_level integer)
    RETURNS TABLE(osm_id bigint, geometry geometry, admin_level smallint, maritime boolean, disputed integer)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

  SELECT
    osm_id, 
    way,
    admin_level::SMALLINT,
    maritime,
    CASE
      WHEN
        tags->'disputed' = 'yes'
        OR tags->'dispute' = 'yes'
        OR (tags->'disputed_by') IS NOT NULL
        OR tags->'status' = 'partially_recognized_state'
      THEN 1
      ELSE 0
    END AS disputed
  FROM 
    admin
  WHERE
    maritime <> TRUE
    AND (
      (
        admin_level = '2' AND zoom_level >= 2 
      )
      OR ( 
        admin_level = '4' AND zoom_level >= 3 
      )
    )
    AND 
      COALESCE(tags->'left:country', '') <> 'Demarcation Zone'
    AND 
      COALESCE(tags->'right:country', '') <> 'Demarcation Zone'
    AND 
      way && bbox
  ;

$BODY$;
