# planet RSS feed aggregator (planet-venus)

class role::planet {

	system_role { "misc::planet-venus": description => "Planet (venus) weblog aggregator" }

	include standard,
	include generic::locales::international

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
	
	$planet_languages = [ "ar", "ca", "cs", "de", "en", "es", "fr", "gmq", "it", "ja", "pl", "pt", "ro", "ru", "sr", "zh", ]
	
	class {'misc::planet-venus':
		planet_domain_name => $planet_domain_name,
		planet_languages => $planet_languages,
	}
}
