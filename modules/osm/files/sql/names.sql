-- SPDX-License-Identifier: Apache-2.0
CREATE OR REPLACE FUNCTION extract_names (tags hstore)
  RETURNS hstore
  AS
  $$
    SELECT
      hstore(array_agg(key), array_agg(value))
      FROM (
        SELECT
            SUBSTRING(key FROM 6) AS key,
            value
          FROM each(tags)
          WHERE key LIKE 'name:%'
      ) AS s(key, value)
      WHERE key NOT LIKE '%:%' -- Anything with a : still is a multi-level one, and not a simple language code
      AND key !~ '.*\d.*' -- matches something like name:en1
      AND key NOT IN ('prefix', 'genitive', 'etymology', 'botanical', 'source', 'left', 'right') -- blacklist common not-languages
  $$
LANGUAGE SQL
IMMUTABLE
STRICT;
