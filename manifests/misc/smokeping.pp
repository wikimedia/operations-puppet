# Smokeping server

class misc::smokeping {

	system_role { "misc::smokeping": description => "Smokeping server" }

	package {
		"smokeping":
		ensure => latest;
	}

	file {
		"/etc/smokeping/config.d/General":
			path => "/etc/smokeping/config.d/General",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/smokeping/General";
	}

	file {
		"/etc/smokeping/config.d/Alerts":
			path => "/etc/smokeping/config.d/Alerts",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/smokeping/Alerts";
	}

	file {
		"/etc/smokeping/config.d/Targets":
			path => "/etc/smokeping/config.d/Targets",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/smokeping/Targets";
	}

	file {
		"/etc/smokeping/config.d/Probes":
			path => "/etc/smokeping/config.d/Probes",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/smokeping/Probes";
	}

}