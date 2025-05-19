-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_transportation(bbox geometry, zoom_level integer)
    RETURNS TABLE(osm_id bigint, geometry geometry, class text, z_order integer, is text)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
  SELECT
    osm_id,
    way,
    class,
    z_order,
    "is"
  FROM (
    SELECT
        osm_id,
        way,
        layer_transportation_name_to_class(highway, railway, access, osm_id) AS class,
        z_order,
        CASE
          -- maybe handle all these cases at the data import?
          WHEN bridge IS NOT NULL AND bridge <> '' AND bridge <> 'no' AND bridge <> '0' THEN 'bridge'
          WHEN tunnel IS NOT NULL AND tunnel <> '' AND tunnel <> 'no' AND tunnel <> '0' THEN 'tunnel'
          ELSE 'road'
        END AS "is"
      FROM
        planet_osm_line
      WHERE
        (
            (
              highway IN ('motorway', -- 'motorway'
                'primary', 'primary_link', 'trunk', 'trunk_link' -- 'main'
              )
              AND zoom_level >= 6
            )
            OR
            ( -- 'main'
              highway IN ('secondary', 'secondary_link')
              AND zoom_level >= 9
            )
            OR
            ( -- 'main'
              highway IN ('tertiary', 'tertiary_link')
              AND zoom_level >= 12
            )
            OR
            ( -- 'street'
              highway IN ('residential', 'unclassified', 'living_street')
              AND zoom_level >= 12
            )
            OR
            ( -- 'street_limited'
              (highway IN ('pedestrian', 'construction') OR access = 'private')
              AND zoom_level >= 12
            )
            OR
            ( -- 'major_rail'
              railway IN ('rail', 'monorail', 'narrow_gauge', 'subway', 'tram')
              AND zoom_level >= 12
            )
            OR
            ( -- 'motorway_link'
              highway IN ('motorway_link')
              AND zoom_level >= 13
            )
            OR
            ( -- 'service'
              highway IN ('service', 'track')
              AND zoom_level >= 14
            )
            OR
            ( -- 'driveway'
              highway IN ('driveway')
              AND zoom_level >= 14
            )
            OR
            ( -- 'path'
              highway IN ('path', 'cycleway', 'ski', 'steps', 'bridleway', 'footway')
              AND zoom_level >= 14
            )
            OR
            ( -- 'minor_rail'
              railway IN ('funicular', 'light_rail', 'preserved')
              AND zoom_level >= 14
            )
          )
        AND way && bbox
    ) AS transportation
    ORDER BY
      layer_transportation_priority_score(class, "is", z_order)
  ;

$BODY$;
