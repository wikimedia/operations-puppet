-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_place_label(bbox geometry, zoom_level integer, pixel_width numeric)
    RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_ text, type text, ldir text, localrank integer)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

  SELECT
    osm_id,
    way,
    name,
    name_,
    "type",
    ldir,
    localrank
  FROM(
  SELECT
    DISTINCT ON (labelgrid(way, 16, pixel_width))
      osm_id,
      way,
      get_label_name(name) AS name,
      (hstore_to_json(extract_names(tags)))::text name_,
      place AS "type",
      'SE' AS ldir,
      1 AS localrank, -- TODO:
      CASE
        WHEN place = 'city' THEN 5000000000 + to_int(population)
        WHEN place = 'town' THEN 3000000000 + to_int(population)
        WHEN place = 'village' THEN 1000000000 + to_int(population)
        ELSE to_int(population)
      END AS sort_order
    FROM
      planet_osm_point
    WHERE
      (
        (
          place = 'city'
          AND zoom_level >= 4
          -- On zoom 4, display cities with 1M+ population. Decrease by 250k every level
          AND (to_int(population) + zoom_level * 250000 - 2000000) > 0
        )
        OR
        (
          place = 'town'
          AND zoom_level >= 9
        )
        OR
        (
          place = 'village'
          AND zoom_level >= 11
        )
        OR
        (
          place IN ('hamlet', 'suburb','neighbourhood')
          AND zoom_level >= 13
        )
      )
      AND
        (name IS NOT NULL AND name <> '')
      AND
        way && ST_Expand(bbox, 64*pixel_width)
    ORDER BY
      labelgrid(way, 16, pixel_width),
      sort_order DESC,
      pg_catalog.length(name) DESC,
      name
  ) data ORDER BY sort_order DESC

$BODY$;
