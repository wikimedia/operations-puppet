# application server base class
class applicationserver {
	case $::operatingsystem {
		debian, ubuntu: {
		}
		default: {
			fail("Module ${module_name} is not supported on ${::operatingsystem}")
		}
	}

	# map tin deploy directory so that git metadata has a place to reference, used by Special:Version
	file { '/a':
		ensure => 'link',
		target => '/apache';
	}

	include apache_packages, service, cron, sudo, config::base
}
