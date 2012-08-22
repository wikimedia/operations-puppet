# planet RSS feed aggregator 2.0 (planet-venus)

class role::planet {

	system_role { "role::planet": description => "Planet (venus) weblog aggregator" }

	# locales are essential for planet. if a new language is added check these too
	include standard,
		generic::locales::international

	# be flexible about labs vs. prod
	case $::realm {
		labs: {
			$planet_domain_name = 'wmflabs.org'
		}
		production: {
			$planet_domain_name = 'wikimedia.org'
		}
		default: {
			fail('unknown realm, should be labs or production')
		}
	}

	# webserver setup
	install_certificate{ "star.${planet_domain_name}": }
	class {'webserver::php5': ssl => 'true'; }
	apache_module { rewrite: name => "rewrite" }

	# dependencies
	Install_certificate["star.${planet_domain_name}"] -> apache_module["rewrite"] -> Class['webserver::php5']

	# list all planet languages here, cronjobs are auto-created from this array
	$planet_languages = [ "ar", "ca", "cs", "de", "en", "es", "fr", "gmq", "it", "ja", "pl", "pt", "ro", "ru", "sr", "zh", ]

	# the actual planet-venus class doing all the reset
	class {'misc::planet-venus':
		planet_domain_name => $planet_domain_name,
		planet_languages => $planet_languages,
	}
}
