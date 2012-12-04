class misc::docsite {

	class {'webserver::php5': ssl => 'true'; }

	file {
		'/etc/apache2/sites-available/doc.wikimedia.org':
			path => '/etc/apache2/sites-available/doc.wikimedia.org',
			mode => 0444,
			owner => root,
			group => root,
			source => 'puppet:///files/apache/sites/doc.wikimedia.org';
		'/srv/org/wikimedia/doc':
			ensure => 'directory';
	}

	apache_site { docs: name => 'doc.wikimedia.org' }
}
