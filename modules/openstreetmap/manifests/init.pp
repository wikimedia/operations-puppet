class openstreetmap::tileserver {
	system_role { "openstreetmap::tileserver": description => "OpenStreetMap tile server" }
	
	include generic::apache::no-default-site
	
	package {
		[ "libapache2-mod-tile", "renderd", "openstreetmap-mapnik-stylesheet-data", "osmosis", "osm2pgsql" ]:
			ensure => latest,
	}
	
	systemuser{ "osm": name => "osm", group => "osm" }

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

	cron { "osm_db_update":
		ensure	=> present,
		command => "/usr/bin/openstreetmap-update-db > /dev/null 2>&1",
		user => "osm",
		minute => [5, 20, 35, 50],
		require => File["/usr/bin/openstreetmap-update-db"],
	}
}
