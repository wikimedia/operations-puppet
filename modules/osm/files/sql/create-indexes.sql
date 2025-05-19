-- SPDX-License-Identifier: Apache-2.0
--
-- Name: admin_maritime; Type: INDEX; Schema: public; Owner: osmimporter; layer_admin:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'admin_maritime'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX admin_maritime ON admin (maritime);
END IF;

END$$;

--
-- Name: admin_level; Type: INDEX; Schema: public; Owner: osmimporter; layer_admin:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'admin_level'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX admin_level ON admin (admin_level);
END IF;

END$$;

--
-- Name: planet_osm_point_name; Type: INDEX; Schema: public; Owner: osmimporter; layer_place_label:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_point_name'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_point_name ON planet_osm_point (name);
END IF;

END$$;

--
-- Name: planet_osm_point_place; Type: INDEX; Schema: public; Owner: osmimporter; layer_place_label:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_point_place'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_point_place ON planet_osm_point (place);
END IF;

END$$;

--
-- Name: planet_osm_point_population; Type: INDEX; Schema: public; Owner: osmimporter; layer_place_label:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_point_population'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_point_population ON planet_osm_point (population);
END IF;

END$$;

--
-- Name: planet_osm_line_access; Type: INDEX; Schema: public; Owner: osmimporter; layer_transportation & layer_transportation_name:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_line_access'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_line_access ON planet_osm_line(access);
END IF;

END$$;

--
-- Name: planet_osm_line_highway; Type: INDEX; Schema: public; Owner: osmimporter; layer_transportation & layer_transportation_name:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_line_highway'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_line_highway ON planet_osm_line(highway);
END IF;

END$$;

--
-- Name: planet_osm_line_railway; Type: INDEX; Schema: public; Owner: osmimporter; layer_transportation & layer_transportation_name:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_line_railway'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_line_railway ON planet_osm_line(railway);
END IF;

END$$;

--
-- Name: planet_osm_polygon_landuse; Type: INDEX; Schema: public; Owner: osmimporter; layer_water:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_polygon_landuse'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_polygon_landuse ON planet_osm_polygon (landuse);
END IF;

END$$;

--
-- Name: planet_osm_polygon_waterway; Type: INDEX; Schema: public; Owner: osmimporter; layer_water:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_polygon_waterway'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_polygon_waterway ON planet_osm_polygon (waterway);
END IF;

END$$;

--
-- Name: planet_osm_polygon_way_area; Type: INDEX; Schema: public; Owner: osmimporter; layer_water:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_polygon_way_area'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_polygon_way_area ON planet_osm_polygon (way_area);
END IF;

END$$;

--
-- Name: planet_osm_polygon_natural; Type: INDEX; Schema: public; Owner: osmimporter; layer_waterway:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_polygon_natural'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_polygon_natural ON planet_osm_polygon ("natural");
END IF;

END$$;

--
-- Name: planet_osm_line_waterway; Type: INDEX; Schema: public; Owner: osmimporter; layer_waterway:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_line_waterway'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_line_waterway ON planet_osm_line (waterway);
END IF;

END$$;

--
-- Name: planet_osm_polygon_landuse_landuse; Type: INDEX; Schema: public; Owner: osmimporter; layer_landuse:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_polygon_landuse_landuse'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_polygon_landuse_landuse ON planet_osm_polygon_landuse(landuse);
END IF;

END$$;

--
-- Name: planet_osm_line_pkey; Type: INDEX; Schema: public; Owner: osmimporter; Tablespace:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_line_pkey'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_line_pkey ON planet_osm_line USING btree (osm_id);
END IF;

END$$;

--
-- Name: planet_osm_point_pkey; Type: INDEX; Schema: public; Owner: osmimporter; Tablespace:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_point_pkey'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_point_pkey ON planet_osm_point USING btree (osm_id);
END IF;

END$$;

--
-- Name: planet_osm_polygon_pkey; Type: INDEX; Schema: public; Owner: osmimporter; Tablespace:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_polygon_pkey'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_polygon_pkey ON planet_osm_polygon USING btree (osm_id);
END IF;

END$$;

--
-- Name: water_polygons_way_idx; Type: INDEX; Schema: public; Owner: osmimporter; Tablespace:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'water_polygons_way_idx'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX water_polygons_way_idx ON water_polygons USING gist (way);
END IF;

END$$;


--
-- Name: planet_osm_polygon_wikidata; Type: INDEX; Schema: public; Owner: osmimporter; Tablespace:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_polygon_wikidata'
    AND    n.nspname = 'public'
    ) THEN

	CREATE INDEX planet_osm_polygon_wikidata ON planet_osm_polygon USING btree (((tags -> 'wikidata'::text))) WHERE (tags ? 'wikidata'::text);
END IF;

END$$;

