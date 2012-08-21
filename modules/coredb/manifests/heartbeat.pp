# coredb heartbeat capability
class coredb::heartbeat {

	require coredb::packages
	include passwords::misc::scripts

	file {
		"/root/.my.cnf":
			owner => root,
			group => root,
			mode => 0400,
			content => template("coredb/root.my.cnf.erb");
		"/etc/init.d/pt-heartbeat":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///modules/coredb/utils/pt-heartbeat.init";
	}

	service { pt-heartbeat:
		require => File["/etc/init.d/pt-heartbeat"],
		subscribe => File["/etc/init.d/pt-heartbeat"],
		ensure => running,
		hasstatus => false;
	}
}
