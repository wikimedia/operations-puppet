# coredb heartbeat capability
class coredb::heartbeat {

	require coredb::packages

	file {
		"/etc/init.d/pt-heartbeat":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/mysql/pt-heartbeat.init";
	}

	service { pt-heartbeat:
		require => File["/etc/init.d/pt-heartbeat"],
		subscribe => File["/etc/init.d/pt-heartbeat"],
		ensure => running,
		hasstatus => false;
	}
}