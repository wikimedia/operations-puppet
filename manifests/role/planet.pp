# planet RSS feed aggregator (planet-venus)

class role::planet {

	system_role { "misc::planet-venus": description => "Planet (venus) weblog aggregator" }

	include standard,
		generic::locales::international

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

	install_certificate{ "star.${planet_domain_name}": }
	class {'webserver::php5': ssl => 'true'; }
	
	Install_certificate["star.${planet_domain_name}"] -> Class['webserver::php5']
	
	$planet_languages = [ "ar", "ca", "cs", "de", "en", "es", "fr", "gmq", "it", "ja", "pl", "pt", "ro", "ru", "sr", "zh", ]

	class {'misc::planet-venus':
		planet_domain_name => $planet_domain_name,
		planet_languages => $planet_languages,
	}
}
