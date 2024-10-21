<!-- SPDX-License-Identifier: Apache-2.0 -->
# Tables catalog

Catalog of MariaDB tables in MediaWiki in production. See T363581 for more information.

Please update this file before deploying changes to production.

## Data model
Each table entry can have these options:
 - name (required): name of the table.
 - source (required): one of the sources in the sources section linking to abstract schema definition of this table. Not required for dropped tables
 - canonicality (required): One of the following options:
  - canonical: Canonical data that their loss would irreversible damage to data integrity. Examples: revision, user, ...
  - canonical with acceptable loss: Canonical data but their loss wouldn't be considered too bad. Examples: recentchanges, cu_changes, ...
  - derivative: Mostly or all are derivative data that can be regenerated from content of pages. Examples: pagelinks, geo_tags, linter, ...
 - visibility (required): Determining data should be replicated to cloud replicas. One of the following options:
  - public: All of the data can be queried by anyyone in the internet. Example: pagelinks
  - partially public: Some parts of data needs to be hidden via views. Example: user
  - private: Should not be replicated to the cloud at all. Example: bot_passwords
 - databases (optional): Where the table can be found. An array of objects.
   Each object should have at least "dbname" or "dblist" and optionally "cluster" (such as "x1")
   Default: wiki's core database.
 - dblist (optional): Database of which wikis can have this table. This is a shortcut for common cases where "databases" would have only one "dblist" entry only.
   Default: all.dblist
