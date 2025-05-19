-- SPDX-License-Identifier: Apache-2.0
/*
  accepts a transportation name type value and maps the value to a class
*/
CREATE OR REPLACE FUNCTION public.layer_transportation_name_to_class(highway text, railway text, access text, osm_id bigint)
  RETURNS text
AS
  $$
    declare
      class_name text;

    BEGIN
      SELECT
        CASE
          WHEN highway IN ('motorway', 'motorway_link', 'driveway') THEN highway
          WHEN highway IN ('primary', 'primary_link', 'trunk', 'trunk_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link') THEN 'main'
          WHEN highway IN ('residential', 'unclassified', 'living_street') THEN 'street'
          WHEN highway IN ('pedestrian', 'construction') OR access = 'private' THEN 'street_limited'
          WHEN railway IN ('rail', 'monorail', 'narrow_gauge', 'subway', 'tram') THEN 'major_rail'
          WHEN highway IN ('service', 'track') THEN 'service'
          WHEN highway IN ('path', 'cycleway', 'ski', 'steps', 'bridleway', 'footway') THEN 'path'
          WHEN railway IN ('funicular', 'light_rail', 'preserved') THEN 'minor_rail'
          ELSE bail_out('Unexpected road row with osm_id=%s', osm_id::TEXT)
        END INTO class_name
      ;

      RETURN class_name;
    END;
  $$ language 'plpgsql';

/*
  layer_transportation_priority_score computes the order priority for the feature based on its
  class: grouped transportation feature type
  is: can be 'tunnel', 'road' or 'bridge'
  z_order: the z-order of the feature as defined by the dataset
*/
CREATE OR REPLACE FUNCTION public.layer_transportation_priority_score(class text, is text, z_order integer)
  RETURNS integer
AS
  $$
    declare
      feature_priority integer;
      feature_boost integer;
      final_score integer;

    BEGIN
      -- setup CTE for order boosting
      WITH ordertable_cte(feature_class, priority) AS (
          VALUES
            ('motorway', 1000),
            ('main', 900),
            ('street', 800),
            ('motorway_link', 700),
            ('street_limited', 600),
            ('driveway', 500),
            ('major_rail', 400),
            ('service', 300),
            ('minor_rail', 200),
            ('path', 100)
      )

      -- feature_priority
      SELECT
        priority
      FROM
        ordertable_cte
      WHERE
        feature_class = class
      INTO
        feature_priority
      ;

      -- feature_boost
      SELECT
        CASE "is"
          WHEN 'tunnel' THEN -100000
          WHEN 'road' THEN 0
          WHEN 'bridge' THEN 100000
          ELSE bail_out('Unexpected layer_transportation_priority_score value for is=%s', "is")::INT
        END INTO feature_boost
      ;

      -- compute final_score
      SELECT
        z_order + feature_priority + feature_boost
      INTO final_score;

      RETURN final_score;
    END;
  $$ language 'plpgsql';

CREATE OR REPLACE FUNCTION public.layer_transportation_name(bbox geometry, zoom_level integer)
    RETURNS TABLE(osm_id bigint, shield text, geometry geometry, name text, name_ text, class text, z_order integer, is text, ref text, reflen integer, len numeric)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
  SELECT
    *
  FROM
    (
      SELECT
          osm_id,
          'default' AS shield,
          way,
          name,
          (hstore_to_json(extract_names(tags)))::text name_,
          layer_transportation_name_to_class(highway, railway, access, osm_id) AS class,
          z_order,
          CASE
            -- maybe handle all these cases at the data import?
            WHEN bridge IS NOT NULL AND bridge <> '' AND bridge <> 'no' AND bridge <> '0' THEN 'bridge'
            WHEN tunnel IS NOT NULL AND tunnel <> '' AND tunnel <> 'no' AND tunnel <> '0' THEN 'tunnel'
            ELSE 'road'
          END AS "is",
          ref,
          pg_catalog.char_length(ref) AS reflen,
          ROUND(Merc_Length(way)) AS len
        FROM
          planet_osm_line AS osm_line
        WHERE
          (
              (
                highway IN (
                    'motorway', 'primary', 'primary_link', 'trunk',
                    'trunk_link', 'secondary', 'secondary_link'
                  )
                AND (
                  (name IS NOT NULL AND name <> '') OR (ref IS NOT NULL AND ref <> '')
                )
                AND zoom_level >= 11
              )
              OR
              ( -- 'main'
                highway IN (
                    'tertiary', 'tertiary_link', 'residential', 'unclassified',
                    'living_street', 'pedestrian', 'construction', 'rail', 'monorail',
                    'narrow_gauge', 'subway', 'tram'
                  )
                AND (name IS NOT NULL AND name <> '')
                AND zoom_level >= 12
              )
              OR
              ( -- 'motorway_link'
                highway IN (
                    'motorway_link', 'service', 'track', 'driveway', 'path',
                    'cycleway', 'ski', 'steps', 'bridleway', 'footway', 'funicular',
                    'light_rail', 'preserved'
                  )
                AND (name IS NOT NULL AND name <> '')
                AND zoom_level >= 14
              )
          )
          AND
            way && bbox
      ) AS transportation
    ORDER BY
      layer_transportation_priority_score(class, "is", z_order)
  ;
$BODY$;
