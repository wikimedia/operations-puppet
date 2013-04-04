class cpufrequtils (
	$governor = "performance",
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

	file { '/etc/default/cpufrequtils':
		content => "GOVERNOR=${governor}",
		require => Package['cpufrequtils'];
	}

	service { 'cpufrequtils':
		enable => true,
		require => Package['cpufrequtils'],
		subscribe => File["/etc/default/cpufrequtils"];
	}
}
