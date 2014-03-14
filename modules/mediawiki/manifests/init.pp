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
	#
	# Timidity is a dependency for the MediaWiki extension Score and is
	# installed via wikimedia-task-appserver.
	#
	# The 'timidity' package used to install the daemon, but it is recommended
	# to disable it anyway. In Precise, the daemon is provided by a package
	# 'timidity-daemon', so we just need to ensure it is not installed to
	# disable it properly.
	package { 'timidity-daemon':
		ensure => absent,
	}

	include users::mwdeploy, users::l10nupdate, users::sudo, sync, cgroup, packages

	if $twemproxy {
		include twemproxy
	}
}
