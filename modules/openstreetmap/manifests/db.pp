class openstreetmap::db {
	system_role { "openstreetmap::db": description => "OpenStreetMap database server" }
	include postgresql

	package {
		"postgresql-contrib":
			ensure => latest;
		"postgresql-client-common":
			ensure => latest;
		"postgis":
			ensure => latest;
		"postgresql-9.1-postgis":
			ensure => latest; 
	}

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
