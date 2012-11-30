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

