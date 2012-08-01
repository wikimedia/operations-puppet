# application server base class
class applicationserver {
	case $::operatingsystem {
		debian, ubuntu: {
		}
		default: {
			fail("Module ${module_name} is not supported on ${::operatingsystem}")
		}
	}

	# Require apaches::files to be in place
	require applicationserver::config::php,
		applicationserver::config::apache,
		applicationserver::config::mail,
		applicationserver::cron,
		applicationserver::nice,
		applicationserver::pybal_check,
		applicationserver::sync,
		applicationserver::syslog

	# Start apache but not at boot
	service { 'apache':
		name => "apache2",
		enable => false,
		ensure => running;
	}

	monitor_service { "appserver http": description => "Apache HTTP",
		check_command => $::realm ? { 'production' => "check_http_wikipedia",
				'labs' => "check_http_url!commons.wikimedia.beta.wmflabs.org|http://commons.wikimedia.beta.wmflabs.org/wiki/Main_Page" }
	}
}