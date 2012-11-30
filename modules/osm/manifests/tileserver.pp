class osm::tileserver(
	$osm_host,
	$postgres_host,
	$htcp_host = undef,
	$admin_email,
	$tile_expiry = 45
	) {

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

	if ( $tile_expiry > 0 ) {
		cron { "delete-old-jetty-logs":
			command => "/usr/bin/find /var/lib/mod_tile/* -mtime +$tile_expiry -delete",
			user => "root",
			day => '*',
			ensure => present,
		}
	}
}
