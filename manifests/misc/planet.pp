# http://planet.wikimedia.org/

# old planet
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

# new planet
class misc::planet-venus( $planet_domain_name, $planet_languages ) {

	$planet_languages_keys = keys($planet_languages)

	# http://intertwingly.net/code/venus/
	package { "planet-venus":
		ensure => latest;
	}

	systemuser { planet: name => "planet", home => "/var/lib/planet", groups => [ "planet" ] }

	File {
		owner => "planet",
		group => "planet",
		mode => 0644,
	}

	file { [ "/var/www/planet", "/var/log/planet", "/usr/share/planet-venus/wikimedia", "/usr/share/planet-venus/theme/wikimedia", "/usr/share/planet-venus/theme/common", "/var/cache/planet" ]:
		ensure => "directory",
		mode => 0755,
	}

	file {
		"/etc/apache2/sites-available/planet.${planet_domain_name}":
			mode => 0444,
			owner => root,
			group => root,
			content => template('apache/sites/planet.erb');
		"/var/www/planet/index.html":
			mode => 0444,
			owner => www-data,
			group => www-data,
			source => "puppet:///files/planet/index.html";
		"/usr/share/planet-venus/theme/wikimedia/index.html.tmpl":
			source => "puppet:///files/planet/theme/index.html.tmpl";
		"/usr/share/planet-venus/theme/common/images/planet-wm2.png":
			source => "puppet:///files/planet/images/planet-wm2.png";
	}

	define planetconfig {

		file {
			"/usr/share/planet-venus/wikimedia/${title}":
				path => "/usr/share/planet-venus/wikimedia/${title}",
				mode => 0755,
				owner => planet,
				group => planet,
				ensure => directory;
			"/usr/share/planet-venus/wikimedia/${title}/config.ini":
				path => "/usr/share/planet-venus/wikimedia/${title}/config.ini",
				ensure => present,
				owner => planet,
				group => planet,
				mode => 0444,
				content => template("planet/${title}_config.erb"),
		}
	}

	planetconfig { $planet_languages_keys: }

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

	planetwwwdir { $planet_languages_keys: }

	define planetcronjob {

		cron {
			"update-${title}-planet":
			ensure => present,
			command => "/usr/bin/planet -v /usr/share/planet-venus/wikimedia/${title}/config.ini > /var/log/planet/${title}-planet.log 2>&1",
			user => 'planet',
			hour => '0',
			minute => '0',
			require => [User['planet']];
		}

	}

	planetcronjob { $planet_languages_keys: }

	define planettheme {

		file {
			"/usr/share/planet-venus/theme/wikimedia/${title}":
				ensure => directory;
			"/usr/share/planet-venus/theme/wikimedia/${title}/index.html.tmpl":
				ensure => present,
				content => template("planet/index.html.tmpl.erb");
			"/usr/share/planet-venus/theme/wikimedia/${title}/config.ini":
				source => "puppet:///files/planet/theme/config.ini";
			"/usr/share/planet-venus/theme/wikimedia/${title}/planet.css":
				source => "puppet:///files/planet/theme/planet.css";


		}


	}

	planettheme { $planet_languages_keys: }

	apache_site { planet: name => "planet.${planet_domain_name}" }

}
