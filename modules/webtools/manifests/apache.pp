class webtools::apache {
	include webserver::php5
	include webtools::libraries

	file {
		"/etc/apache2/sites-available/default":
			source => "puppet:///modules/webtools/files/apache-default";
		"/etc/apache2/sites-enabled/000-default":
			ensure => link,
			target => "/etc/apache2/sites-available/default";
	}
}

