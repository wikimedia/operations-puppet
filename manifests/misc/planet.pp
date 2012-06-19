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
	system_role { "misc::planet-venus": description => "Planet (venus) weblog aggregator" }

	$planet_languages=["ar", "ca", "cs", "de", "en", "es", "fr", "gmq", "it", "ja", "pl", "pt", "ro", "ru", "sr", "zh"]

	package { "planet-venus":
		ensure => latest;
	}

	systemuser { planet: name => "planet", home => "/var/lib/planet", groups => [ "planet" ] }

	file {
		"/var/www/index.html":
			path => "/var/www/index.html",
			mode => 0444,
			owner => www-data,
			group => www-data,
			source => "puppet:///files/planet/index.html";
		"/var/log/planet":
			path => "/var/log/planet",
			mode => 0755,
			owner => planet,
			group => planet,
			ensure => directory;
		"/usr/local/bin/update-planets":
			path => "/usr/local/bin/update-planets",
			mode => 0550,
			owner => planet,
			group => planet,
			source => "puppet:///files/planet/update-planets";
	}

	define planetconfig {

		file {
			"/usr/share/planet-venus/config/${title}":
				path => "/usr/share/planet-venus/wikimedia/${title}/config.ini",
				ensure => present,
				owner => planet,
				group => planet,
				mode => 0444,
				source => "puppet:///files/planet/${title}_config.ini";
		}
	}

	planetconfig { $planet_languages: }

	define planetwwwdir {

		file {
			"/var/www/planet/${title}":
				path => "/var/www/planet/${title}",
				ensure => directory,
				owner => planet,
				group => www-data,
				mode => 0755,
		}
	}

	planetwwwdir { $planet_languages: }

	cron {
		"update-all-planets":
		ensure => present,
		command => "/usr/local/bin/update-planets",
		user => 'planet',
		hour => '0',
		minute => '0',
		require => [user['planet'], file['/usr/local/bin/update-planets']];
	}

}
