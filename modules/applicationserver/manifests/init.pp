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
		applicationserver::nice

	# Start apache but not at boot
	service { 'apache':
		name => "apache2",
		enable => false,
		ensure => running;
	}
}