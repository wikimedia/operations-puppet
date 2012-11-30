class osm::importer( $postgres_host ) {
	include osm::importer::files

	systemuser{ "osm": name => "osm" }

	package { [ "osmosis", "osm2pgsql" ]:
		ensure => latest,
	}

	cron { "osm_db_update":
		ensure	=> present,
		command => "/usr/bin/openstreetmap-update-db > /dev/null 2>&1",
		user => "osm",
		minute => [5, 20, 35, 50],
		require => File["/usr/bin/openstreetmap-update-db"],
	}
}
