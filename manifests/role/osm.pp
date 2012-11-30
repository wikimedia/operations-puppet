class role::osm::tileserver {
	system_role { "osm::tileserver": description => "OpenStreetMap tile server" }

	include standard

	if ( $::realm == "production" ) {
		fail( "Not implemented" )
	} else {
		$postgres_host = 'mobile-pg'
		class {
			"::osm::tileserver":
				osm_host => 'osm.wmflabs.org',
				postgres_host => $postgres_host,
				admin_email => 'nobody@nowhere';
		}

		class {
			"osm::importer":
				postgres_host => $postgres_host;
		}
	}
}

class role::osm::db {
	system_role { "osm::db": description => "OpenStreetMap database server" }

	include standard,
		osm::db
}

