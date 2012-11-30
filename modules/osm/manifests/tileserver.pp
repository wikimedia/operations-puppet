class osm::tileserver( $osm_host, $postgres_host, $htcp_host = undef, $admin_email ) {

	class { "osm::tileserver::files":
		osm_host => $osm_host,
		admin_email => $admin_email,
		htcp_host => $htcp_host,
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
