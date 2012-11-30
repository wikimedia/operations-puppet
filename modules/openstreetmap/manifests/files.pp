class openstreetmap::files
	file {
		"/etc/apache2/mods-enabled/tile.load":
			notify	=> Service["apache2"],
			ensure => 'link',
			target => '/etc/apache2/mods-available/tile.load',
			require => Package["libapache2-mod-tile"],
	}

	file {
		"/etc/apache2/sites-available/tileserver":
			notify	=> Service["apache2"],
			owner => root,
			group => root,
			mode => 0744,
			source => "puppet:///openstreetmap/tileserver_site",
			require => Package["libapache2-mod-tile"],
	}

	file {
		"/etc/apache2/sites-enabled/tileserver_site":
			notify	=> Service["apache2"],
			ensure => 'link',
			target => '/etc/apache2/sites-available/tileserver_site',
			require => Package["libapache2-mod-tile"],
	}

	file {
		"/etc/apache2/sites-enabled/000-default":
			notify	=> Service["apache2"],
			ensure => 'absent',
			require => Package["libapache2-mod-tile"],
	}

	file {
		"/etc/renderd.conf":
			notify => Service["apache2", "renderd"],
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/openstreetmap/renderd.conf",
			require => Package["renderd"],
	}

	file {
		"/etc/mapnik-osm-data/inc/datasource-settings.xml.inc":
			notify => Service["apache2", "renderd"],
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/openstreetmap/datasource-settings.xml.inc",
			require => Package["openstreetmap-mapnik-stylesheet-data"],
	}

	file { "/var/lib/mod_tile/.osmosis/":
		ensure => directory, # so make this a directory
		recurse => true, # enable recursive directory management
		owner => "osm",
		group => "osm",
		mode => 0644, # this mode will also apply to files from the source directory
		require => Package["osmosis"],
	}

	file {
		"/var/lib/mod_tile/.osmosis/configuration.txt":
			owner => osm,
			group => osm,
			mode => 0644,
			source => "puppet:///files/openstreetmap/osmosis.configuration.txt",
			require => Package["osmosis"],
	}

	file { "/var/log/osm/":
		ensure => directory, # so make this a directory
		recurse => true, # enable recursive directory management
		owner => "osm",
		group => "osm",
		mode => 0644, # this mode will also apply to files from the source directory
		require => User["osm"],
	}

	file { "/usr/bin/openstreetmap-import-planet":
		mode => 0755,
		source => "puppet:///files/openstreetmap/import-planet",
		require => User["osm"],
	
	}

	file { "/usr/bin/openstreetmap-update-db":
		mode => 0755,
		source => "puppet:///files/openstreetmap/load-next",
		require => User["osm"],
	}
}
