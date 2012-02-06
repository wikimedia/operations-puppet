# http://planet.wikimedia.org/
class misc::planet {
	#The host of this role must have the star certificate installed on it
	system_role { "misc::planet": description => "Planet weblog aggregator" }

	systemuser { planet: name => "planet", home => "/var/lib/planet", groups => [ "planet" ] }

	class {'webserver::php5': ssl => 'true'; }

	include generic::locales::international

	file {
		"/etc/apache2/sites-available/planet.wikimedia.org":
			path => "/etc/apache2/sites-available/planet.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/planet.wikimedia.org";
	}

	apache_site { planet: name => "planet.wikimedia.org" }

	package { "python2.6":
		ensure => latest;
	}
}

# http://intertwingly.net/code/venus/
class misc::planet-venus {
	package { "planet-venus":
		ensure => latest;
	}

	file {
		"/var/www/index.html":
			path => "/var/www/index.html",
			mode => 0444,
			owner => www-data,
			group => www-data,
			source => "puppet:///files/planet/index.html";
	}
}
