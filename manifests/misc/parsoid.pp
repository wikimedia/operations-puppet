
@monitor_group { "parsoid_eqiad": description => "eqiad parsoid servers" }
@monitor_group { "parsoid_pmtpa": description => "pmtpa parsoid servers" }

class misc::parsoid {
	package { [ "nodejs", "npm", "build-essential" ]:
		ensure => latest
	}

	file {
		"/var/lib/parsoid":
			ensure => directory,
			owner => parsoid,
			group => parsoid,
			mode => 0755;
		"/etc/init.d/parsoid":
			source => "puppet:///files/misc/parsoid.init",
			owner => root,
			group => root,
			mode => 0555;
		"/usr/bin/parsoid":
			source => "puppet:///files/misc/parsoid",
			owner => root,
			group => root,
			mode => 0555;
	}

	systemuser {
		parsoid:
			name => "parsoid",
			default_group => "parsoid",
			home => "/var/lib/parsoid";
	}

	service {
		"parsoid":
			hasstatus => true,
			hasrestart => true,
			enable => true,
			ensure => running,
			require => [File["/etc/init.d/parsoid"]];
	}

	monitor_service { "parsoid": description => "Parsoid", check_command => "check_http_lvs_on_port!{$hostname}!8000!/_html/" }
}
