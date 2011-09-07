# exim.pp

class exim::packages {
        package { [ "exim4-daemon-light", "exim4-config" ]:
                ensure => latest;
        }

	if ! $exim_queuerunner {
		$exim_queuerunner = 'queueonly'
	}

        file {
                "/etc/default/exim4":
                        owner => root,
                        group => root,
                        mode => 0644,
                        content => template("exim/exim4.default.erb");
	}
}

class exim::service {
        service { "exim4":
                require => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"], Package[exim4-daemon-light] ],
                subscribe => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"] ],
                ensure => running;
        }
}

class exim::simple-mail-sender {
        $exim_queuerunner = 'queueonly'

	require exim::packages

	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/exim/exim4.minimal.conf";
	}

	include exim::service
}

class exim::rt {
        $exim_queuerunner = 'combined'

	require exim::packages

	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/exim/exim4.rt.conf";
	}

	include exim::service

	# Nagios monitoring
	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
}
