# PoolCounter server
# See http://wikitech.wikimedia.org/view/PoolCounter

class role::poolcounter {
	include nrpe

	system_role { 'role::poolcounter': description => 'PoolCounter server' }

	monitor_service { "poolcounterd":
		description => "poolcounter",
		check_command => "nrpe_check_poolcounterd"
	}

	package { "poolcounter":
		ensure => latest;
	}

	service { "poolcounter":
		require => Package["poolcounter"],
		ensure => running;
	}
}

