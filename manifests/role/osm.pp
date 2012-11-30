class role::osm::tileserver {
	system_role { "osm::tileserver": description => "OpenStreetMap tile server" }

	include standard,
		generic::apache::no-default-site

	if ( $::realm == "production" ) {
		fail( "Not implemented" );
	} else {
		include osm::importer

		class { "osm::tileserver":
			osm_host => 'osm.wmflabs.org',
			postgres_host => 'mobile-pg',
			admin_email => 'nobody@nowhere',
		}
	}
}

class role::osm::db {
	system_role { "osm::db": description => "OpenStreetMap database server" }

	include standard,
		osm::db
}

