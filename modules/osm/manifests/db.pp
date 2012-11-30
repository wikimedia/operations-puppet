class osm::db {
	include postgresql,
		osm::db::setup

	package { 
		[ "postgresql-contrib", "postgis", "postgresql-9.1-postgis" ]:
			ensure => latest,
	}
}

