class mailman::base {

	package { [ "mailman" ]:
		ensure => latest;
	}

	file {
		"/etc/aliases":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/mailman/aliases";
		"/etc/mailman/mm_cfg.py":
			require => Package[mailman],
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/mailman/mm_cfg.py";

	}

	# lighttpd is used for the mailman UI
		
	package { "lighttpd":
			ensure => latest;
	}

	file { "lighttpd.conf":
			mode => 0444,
			owner => root,
			group => root,
			path => "/etc/lighttpd/lighttpd.conf",
			source => "puppet:///files/lighttpd/list-server.conf";
	}

	service { "lighttpd":
			require => [ File["lighttpd.conf"], Package[lighttpd] ],
			subscribe => File["lighttpd.conf"],
			ensure => running;
	}

	# Monitoring
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
}
