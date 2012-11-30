class osm::tileserver::files( $osm_host, $admin_email ) {
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
			content => template( "osm/tileserver_site.erb" ),
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
			source => "puppet:///osm/renderd.conf",
			require => Package["renderd"],
	}

	file {
		"/etc/mapnik-osm-data/inc/datasource-settings.xml.inc":
			notify => Service["apache2", "renderd"],
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///osm/datasource-settings.xml.inc",
			require => Package["openstreetmap-mapnik-stylesheet-data"],
	}
}
