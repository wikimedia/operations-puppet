# PoolCounter server
# See http://wikitech.wikimedia.org/view/PoolCounter

class poolcounter {
	include nrpe

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

