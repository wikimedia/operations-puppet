# application server base class
class applicationserver {
	case $::operatingsystem {
		debian, ubuntu: {
		}
		default: {
			fail("Module ${module_name} is not supported on ${::operatingsystem}")
		}
	}

	include apache_packages, service, cron, sudo, config::base
}
