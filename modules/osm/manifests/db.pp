class osm::db {
	system_role { "openstreetmap::db": description => "OpenStreetMap database and Osmosis server" }
	include postgresql,
		osm::db::files,
		osm::db::setup

	package { 
		[ "postgresql-contrib", "postgis", "postgresql-9.1-postgis", "osmosis", "osm2pgsql" ]:
			ensure => latest,
	}

	systemuser{ "osm": name => "osm" }

	cron { "osm_db_update":
		ensure	=> present,
		command => "/usr/bin/openstreetmap-update-db > /dev/null 2>&1",
		user => "osm",
		minute => [5, 20, 35, 50],
		require => File["/usr/bin/openstreetmap-update-db"],
	}
}

class osm::db::setup {
	postgresql::createuser { "osm": }
	postgresql::createuser { "www-data": }
	postgresql::createdb { "osm_mapnik":
		sqlowner => "osm",
	}

	postgresql::sqlfileexec { "postgis":
		database => "osm_mapnik",
		sql => "/usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql",
		sqlcheck => "SELECT PostGIS_full_version();",
	}

	postgresql::sqlfileexec { "postgis-ref-sys":
		database => "osm_mapnik",
		sql => "/usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql",
		sqlcheck => "SELECT srid FROM spatial_ref_sys WHERE srid='900913';",
	}

	postgresql::sqlexec { "permissions":
		database => "osm_mapnik",
		sql => "ALTER TABLE geometry_columns OWNER TO osm; ALTER TABLE spatial_ref_sys OWNER TO osm; GRANT SELECT ON geometry_columns TO PUBLIC; GRANT SELECT ON spatial_ref_sys TO PUBLIC;",
		sqlcheck => "",
	}

	postgresql::sqlexec { "hstore":
		database => "osm_mapnik",
		sql => "CREATE EXTENSION hstore;",
		sqlcheck => "SELECT extname FROM pg_extension WHERE extname='hstore';",
	}
}
