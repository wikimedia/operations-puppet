-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_country_label(bbox geometry, zoom_level integer, pixel_width numeric)
    RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_ text, scalerank integer, code text)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

  SELECT
    osm_id,
    way,
    name,
    (hstore_to_json(extract_names(tags)))::text name_,
    CASE
      WHEN to_int(population) >= 250000000 THEN 1
      WHEN to_int(population) BETWEEN 100000000 AND  250000000 THEN 2
      WHEN to_int(population) BETWEEN 50000000 AND 100000000 THEN 3
      WHEN to_int(population) BETWEEN 25000000 AND 50000000 THEN 4
      WHEN to_int(population) BETWEEN 10000000 AND 25000000 THEN 5
      WHEN to_int(population) < 10000000 THEN 6
    END scalerank,
    COALESCE(tags->'ISO3166-1', tags->'country_code_iso3166_1_alpha_2') code
  FROM
    planet_osm_point
  WHERE
    place = 'country'
    AND zoom_level BETWEEN 3 AND 10
    AND way && ST_Expand(bbox, 64*pixel_width)
  ORDER BY
    to_int(population) DESC NULLS LAST
  ;

$BODY$;
