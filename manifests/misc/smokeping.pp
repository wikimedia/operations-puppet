# Smokeping server

class misc::smokeping {

	system_role { "misc::smokeping": description => "Smokeping server" }

	package {
		"smokeping":
		ensure => latest;
	}

	file { "/etc/smokeping/config.d/" :
		require => Package[smokeping],
		ensure => directory,
		recurse => true,
		owner => "root",
		group => "root",
		mode => 0444,
		source => "puppet:///files/smokeping";
	}

	service { smokeping:
		require => [ Package[smokeping],
		File["/etc/smokeping/config.d" ] ],
		subscribe => File["/etc/smokeping/config.d" ],
		ensure => running;
	}

}