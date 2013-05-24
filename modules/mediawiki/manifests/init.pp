# mediawiki installation base class
class mediawiki($twemproxy = true) {
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

	if $twemproxy {
		include twemproxy
	}
}
