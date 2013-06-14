class exim::simple-mail-sender {
	class { "exim::config": queuerunner => "queueonly" }
	Class["exim::config"] -> Class[wmrole::exim::simple-mail-sender]

	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			content => template("exim/exim4.minimal.erb");
	}

	include exim::service
}
