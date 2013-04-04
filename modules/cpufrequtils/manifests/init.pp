class cpufrequtils (
	$governor = 'performance',
) {
	case $::operatingsystem {
		debian, ubuntu: {
		}
		default: {
			fail("Module ${module_name} is not supported on ${::operatingsystem}")
		}
	}

	package { 'cpufrequtils':
		ensure => present;
	}

	# start at boot
	service { 'cpufrequtils':
		enable => true,
		require => Package['cpufrequtils'],
	}

	file { '/etc/default/cpufrequtils':
		content => "GOVERNOR=${governor}\n",
		notify => Exec['apply cpufrequtils'],
		require => Package['cpufrequtils'];
	}

	exec { 'apply cpufrequtils':
		command => '/etc/init.d/cpufrequtils start',
		refreshonly => true
	}
}
