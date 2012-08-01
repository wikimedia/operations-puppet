# mediawiki installation base class

class mediawiki {
	case $::operatingsystem {
		debian, ubuntu: {
		}
		default: {
			fail("Module ${module_name} is not supported on ${::operatingsystem}")
		}
	}

	include mediawiki::users
	include mediawiki::sync
}