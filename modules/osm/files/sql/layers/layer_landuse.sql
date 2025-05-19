-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION public.layer_landuse(bbox geometry, zoom_level integer)
    RETURNS TABLE(osm_id bigint, geometry geometry, class text, z_order integer, way_area real)
    LANGUAGE 'sql'
    COST 100
    IMMUTABLE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
  SELECT
    osm_id,
    way,
    CASE
      WHEN "natural" = 'wood' OR landuse IN ('wood', 'forest') THEN 'wood'
      WHEN leisure IN ('national_reserve', 'nature_reserve', 'golf_course') OR boundary = 'national_park' THEN 'park'
      WHEN landuse IN ('cemetery', 'industrial') THEN landuse
      WHEN aeroway IS NOT NULL AND aeroway <> '' THEN 'industrial'
      WHEN landuse = 'village_green' OR leisure IN ('park', 'playground') THEN 'park'
      WHEN amenity IN ('school', 'university') THEN 'school'
      WHEN amenity = 'hospital' THEN 'hospital'
      ELSE bail_out('Unexpected landuse row with osm_id=%s', osm_id::TEXT)
    END AS class,
    z_order,
    area
  FROM (
    SELECT
      osm_id,
      aeroway,
      amenity,
      area,
      landuse,
      leisure,
      name,
      boundary,
      "natural",
      z_order,
      way
    FROM
      planet_osm_polygon_landuse_gen_z6
    WHERE
      zoom_level = 6 AND
      (
        "natural" = 'wood'
        OR landuse IN ('wood', 'forest')
        OR leisure IN ('national_reserve', 'nature_reserve', 'golf_course')
        OR boundary = 'national_park'
      )
    UNION ALL

    SELECT
      osm_id,
      aeroway,
      amenity,
      area,
      landuse,
      leisure,
      name,
      boundary,
      "natural",
      z_order,
      way
    FROM
      planet_osm_polygon_landuse_gen_z7
    WHERE
      zoom_level = 7 AND
      (
        "natural" = 'wood'
        OR landuse IN ('wood', 'forest')
        OR leisure IN ('national_reserve', 'nature_reserve', 'golf_course')
        OR boundary = 'national_park'
      )
    UNION ALL

    SELECT
      osm_id,
      aeroway,
      amenity,
      area,
      landuse,
      leisure,
      name,
      boundary,
      "natural",
      z_order,
      way
    FROM
      planet_osm_polygon_landuse_gen_z8
    WHERE
      zoom_level = 8 AND
      (
        "natural" = 'wood'
        OR landuse IN ('wood', 'forest')
        OR leisure IN ('national_reserve', 'nature_reserve', 'golf_course')
        OR boundary = 'national_park'
      )
    UNION ALL

    SELECT
      osm_id,
      aeroway,
      amenity,
      area,
      landuse,
      leisure,
      name,
      boundary,
      "natural",
      z_order,
      way
    FROM
      planet_osm_polygon_landuse_gen_z9
    WHERE
      zoom_level = 9 AND
      (
        "natural" = 'wood'
        OR landuse IN ('wood', 'forest')
        OR leisure IN ('national_reserve', 'nature_reserve', 'golf_course')
        OR boundary = 'national_park'
      )
    UNION ALL

    SELECT
      osm_id,
      aeroway,
      amenity,
      area,
      landuse,
      leisure,
      name,
      boundary,
      "natural",
      z_order,
      way
    FROM
      planet_osm_polygon_landuse_gen_z10
    WHERE
      zoom_level = 10 AND
      (
        "natural" = 'wood'
        OR landuse IN ('wood', 'forest')
        OR leisure IN ('national_reserve', 'nature_reserve', 'golf_course')
        OR boundary = 'national_park'
        OR landuse IN ('cemetery', 'industrial', 'village_green')
        OR (aeroway IS NOT NULL AND aeroway <> '')
        OR leisure IN ('park', 'playground')
        OR amenity IN ('school', 'university')
      )
    UNION ALL

    SELECT
      osm_id,
      aeroway,
      amenity,
      area,
      landuse,
      leisure,
      name,
      boundary,
      "natural",
      z_order,
      way
    FROM
      planet_osm_polygon_landuse_gen_z11
    WHERE
      zoom_level = 11 AND
      (
        "natural" = 'wood'
        OR landuse IN ('wood', 'forest')
        OR leisure IN ('national_reserve', 'nature_reserve', 'golf_course')
        OR boundary = 'national_park'
        OR landuse IN ('cemetery', 'industrial', 'village_green')
        OR (aeroway IS NOT NULL AND aeroway <> '')
        OR leisure IN ('park', 'playground')
        OR amenity IN ('school', 'university')
      )
    UNION ALL

    SELECT
      osm_id,
      aeroway,
      amenity,
      area,
      landuse,
      leisure,
      name,
      boundary,
      "natural",
      z_order,
      way
    FROM
      planet_osm_polygon_landuse_gen_z12
    WHERE
      zoom_level = 12 AND
      (
        "natural" = 'wood'
        OR landuse IN ('wood', 'forest')
        OR leisure IN ('national_reserve', 'nature_reserve', 'golf_course')
        OR boundary = 'national_park'
        OR landuse IN ('cemetery', 'industrial', 'village_green')
        OR (aeroway IS NOT NULL AND aeroway <> '')
        OR leisure IN ('park', 'playground')
        OR amenity IN ('school', 'university', 'hospital')
      )
    UNION ALL

    SELECT
      osm_id,
      aeroway,
      amenity,
      area,
      landuse,
      leisure,
      name,
      boundary,
      "natural",
      z_order,
      way
    FROM
      planet_osm_polygon_landuse_gen_z13
    WHERE
      zoom_level = 13 AND
      (
        "natural" = 'wood'
        OR landuse IN ('wood', 'forest')
        OR leisure IN ('national_reserve', 'nature_reserve', 'golf_course')
        OR boundary = 'national_park'
        OR landuse IN ('cemetery', 'industrial', 'village_green')
        OR (aeroway IS NOT NULL AND aeroway <> '')
        OR leisure IN ('park', 'playground')
        OR amenity IN ('school', 'university', 'hospital')
      )
    UNION ALL

    SELECT
      osm_id,
      aeroway,
      amenity,
      area,
      landuse,
      leisure,
      name,
      boundary,
      "natural",
      z_order,
      way
    FROM
      planet_osm_polygon_landuse
    WHERE
      zoom_level >= 14 AND
      (
        "natural" = 'wood'
        OR landuse IN ('wood', 'forest')
        OR leisure IN ('national_reserve', 'nature_reserve', 'golf_course')
        OR boundary = 'national_park'
        OR landuse IN ('cemetery', 'industrial', 'village_green')
        OR (aeroway IS NOT NULL AND aeroway <> '')
        OR leisure IN ('park', 'playground')
        OR amenity IN ('school', 'university', 'hospital')
      )
    ) AS layer_data
    WHERE
      way && bbox
    ORDER BY z_order, area DESC
  ;
$BODY$;
