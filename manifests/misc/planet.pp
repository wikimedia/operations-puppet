# http://planet.wikimedia.org/
class misc::planet {
	system_role { "misc::planet": description => "Planet weblog aggregator" }

	systemuser { planet: name => "planet", home => "/var/lib/planet", groups => [ "planet" ] }

	class {'generic::webserver::php5': ssl => 'true'; }

	include generic::locales::international

	file {
		"/etc/apache2/sites-available/planet.wikimedia.org":
			path => "/etc/apache2/sites-available/planet.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/planet.wikimedia.org";
	}

	install_certificate{ "star.wikimedia.org": }
	apache_site { planet: name => "planet.wikimedia.org" }

	package { "python2.6":
		ensure => latest;
	}
}
