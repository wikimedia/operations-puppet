class osm::db::setup {
	include osm::db::setup::basic,
		osm::db::setup::all

	Class['osm::db::setup::basic'] -> Class['osm::db::setup::all']
}

class osm::db::setup::basic {
	postgresql::createuser { "osm": }
	postgresql::createuser { "www-data": }
	postgresql::createdb { "osm_mapnik":
		sqlowner => "osm",
	}
}

class osm::db::setup::all {
	postgresql::sqlfileexec { "postgis":
		database => "osm_mapnik",
		sql => "/usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql",
		sqlcheck => "SELECT PostGIS_full_version();",
	}

	postgresql::sqlfileexec { "postgis-ref-sys":
		database => "osm_mapnik",
		sql => "/usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql",
		sqlcheck => "SELECT srid FROM spatial_ref_sys WHERE srid='900913';",
		require => Postgresql::Sqlfileexec["postgis"],
	}

	postgresql::sqlexec { "permissions":
		database => "osm_mapnik",
		sql => "ALTER TABLE geometry_columns OWNER TO osm; ALTER TABLE spatial_ref_sys OWNER TO osm; GRANT SELECT ON geometry_columns TO PUBLIC; GRANT SELECT ON spatial_ref_sys TO PUBLIC;",
		sqlcheck => "",
		require => Postgresql::Sqlfileexec["postgis"],
	}

	postgresql::sqlexec { "hstore":
		database => "osm_mapnik",
		sql => "CREATE EXTENSION hstore;",
		sqlcheck => "SELECT extname FROM pg_extension WHERE extname='hstore';",
	}
}

