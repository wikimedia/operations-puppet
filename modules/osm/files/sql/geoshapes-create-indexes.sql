-- SPDX-License-Identifier: Apache-2.0
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

    CREATE INDEX planet_osm_polygon_wikidata
      ON planet_osm_polygon ((tags -> 'wikidata'))
      WHERE tags ? 'wikidata';

END IF;

END$$;

--
-- Name: planet_osm_line_wikidata; Type: INDEX; Schema: public; Owner: osmimporter; Tablespace:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'planet_osm_line_wikidata'
    AND    n.nspname = 'public'
    ) THEN

    CREATE INDEX planet_osm_line_wikidata
      ON planet_osm_line ((tags -> 'wikidata'))
      WHERE tags ? 'wikidata';

END IF;

END$$;

--
-- Name: wikidata_relation_members_idx; Type: INDEX; Schema: public; Owner: osmimporter; Tablespace:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'wikidata_relation_members_idx'
    AND    n.nspname = 'public'
    ) THEN

    CREATE INDEX wikidata_relation_members_idx ON wikidata_relation_members (wikidata);

END IF;

END$$;

--
-- Name: wikidata_relation_polygon_idx; Type: INDEX; Schema: public; Owner: osmimporter; Tablespace:
--

DO $$
BEGIN

IF NOT EXISTS (
    SELECT 1
    FROM   pg_class c
    JOIN   pg_namespace n ON n.oid = c.relnamespace
    WHERE  c.relname = 'wikidata_relation_polygon_idx'
    AND    n.nspname = 'public'
    ) THEN

    CREATE INDEX wikidata_relation_polygon_idx ON wikidata_relation_polygon (wikidata);

END IF;

END$$;
