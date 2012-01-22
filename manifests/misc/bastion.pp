# misc/bastion.pp

# bastion hosts

class misc::bastionhost {
	system_role { "misc::bastionhost": description => "Bastion" }

	require mysql::client
	
	package { "irssi":
		ensure => absent;
<<<<<<< HEAD   (8c6996 Ensuring this returns true)
=======
		"traceroute-nanog":
		ensure => absent;
		"traceroute":
		ensure =>latest;
>>>>>>> BRANCH (41cb7c uh oh, tabs)
	}

	file { "/etc/sudoers":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/sudo/sudoers.appserver";
	}
}
