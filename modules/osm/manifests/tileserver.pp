class osm::tileserver( $osm_host, $postgres_host, $admin_email ) {

	class { "osm::tileserver::files":
		osm_host => $osm_host,
		admin_email => $admin_email,
	}

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
