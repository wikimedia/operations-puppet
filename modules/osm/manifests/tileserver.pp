class osm::tileserver( $postgres_host ) {
	system_role { "openstreetmap::tileserver": description => "OpenStreetMap tile server" }
	
	include #generic::apache::no-default-site,
		osm::tileserver::files
	
	package {
		[ "libapache2-mod-tile", "renderd", "openstreetmap-mapnik-stylesheet-data" ]:
			ensure => latest,
	}
	
	service {
		"apache2":
			ensure => running,
			enable => "true",
			require => Package["libapache2-mod-tile"],
			hasrestart => "true",
	}

	service {
		"renderd":
			ensure => running,
			enable => "true",
			require => Package["renderd"],
			hasrestart => "true",
	}
}
