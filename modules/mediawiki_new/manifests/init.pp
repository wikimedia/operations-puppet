# mediawiki installation base class
## TODO: rename to just mediawiki after full transition to module
class mediawiki_new {
	case $::operatingsystem {
		debian, ubuntu: {
		}
		default: {
			fail("Module ${module_name} is not supported on ${::operatingsystem}")
		}
	}

	# Disable timidity-daemon
	# It's recommended by timidity and there's no simple way to avoid installing it
	service { 'timidity':
		enable => false,
		ensure => stopped;
	}

	include users::mwdeploy, users::l10nupdate, users::sudo, sync, cgroup, packages
}
