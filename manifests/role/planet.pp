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
	Class['webserver::php5'] -> apache_module["rewrite"] -> Install_certificate["star.${planet_domain_name}"]

	# list all planet languages here, configs,dirs,cronjobs are auto-created from this array
	# $planet_languages = [ "ar", "ca", "cs", "de", "en", "es", "fr", "gmq", "it", "ja", "pl", "pt", "ro", "ru", "sr", "zh", ]

	# languages and translations for the index.html.tmlp
	$planet_languages = {
		ar => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		ca => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		cs => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		de => {
			'subscribe' => 'Abonnieren',
			'subscriptions' => 'Teilnehmer',
			'lastupdated' => 'Zuletzt aktualisiert',
		},
		en => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		es => { 'subscribe' => 'Suscribir',
			'subscriptions' => 'Suscripciones',
			'lastupdated' => 'Last updated',
		},
		fr => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		gmq => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		it => {
			'subscribe' => 'Abbonati',
			'subscriptions' => 'Sottoscrizioni',
			'lastupdated' => 'Last updated',
		},
		ja => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		pl => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		pt => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		ro => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		ru => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		sr => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated',
		},
		zh => {
			'subscribe' => 'Subscribe',
			'subscriptions' => 'Subscriptions',
			'lastupdated' => 'Last updated'
		},
	}

	# the actual planet-venus class doing all the rest
	class {'misc::planet-venus':
		planet_domain_name => $planet_domain_name,
		planet_languages => $planet_languages,
	}
}

