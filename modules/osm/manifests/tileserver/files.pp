class osm::tileserver::files( $osm_host, $admin_email, $htcp_host = undef ) {
	file {
		"/etc/apache2/mods-enabled/tile.load":
			notify	=> Service["apache2"],
			ensure => 'link',
			target => '/etc/apache2/mods-available/tile.load',
			require => Package["libapache2-mod-tile"];
		"/etc/apache2/sites-available/tileserver_site":
			notify	=> Service["apache2"],
			owner => root,
			group => root,
			mode => 0444,
			content => template( "osm/tileserver_site.erb" ),
			require => Package["libapache2-mod-tile"];
		"/etc/apache2/sites-enabled/tileserver_site":
			notify	=> Service["apache2"],
			ensure => 'link',
			target => '/etc/apache2/sites-available/tileserver_site',
			require => Package["libapache2-mod-tile"];
		"/etc/apache2/sites-enabled/000-default":
			notify	=> Service["apache2"],
			ensure => 'absent',
			require => Package["libapache2-mod-tile"];
		"/etc/renderd.conf":
			notify => Service["apache2", "renderd"],
			owner => root,
			group => root,
			mode => 0444,
			content => template( "osm/renderd.conf.erb" ),
			require => Package["renderd"];
		"/etc/mapnik-osm-data/inc/datasource-settings.xml.inc":
			notify => Service["apache2", "renderd"],
			owner => root,
			group => root,
			mode => 0444,
			content => template( "osm/datasource-settings.xml.inc.erb" ),
			require => Package["openstreetmap-mapnik-stylesheet-data"];
	}

	# Not useful in production, useful for testing
	if $::realm == 'production' {
		file { "/var/www/osm/slippymap.html":
			ensure => absent,
		}
	}
}
