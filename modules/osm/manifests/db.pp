class osm::db {
	system_role { "openstreetmap::db": description => "OpenStreetMap database and Osmosis server" }
	include postgresql,
		osm::db::setup

	package { 
		[ "postgresql-contrib", "postgis", "postgresql-9.1-postgis" ]:
			ensure => latest,
	}
}

