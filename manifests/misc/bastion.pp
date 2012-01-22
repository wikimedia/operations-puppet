# misc/bastion.pp

# bastion hosts

class misc::bastionhost {
	system_role { "misc::bastionhost": description => "Bastion" }

	require mysql::client
	
	package { "irssi":
		ensure => absent;
<<<<<<< HEAD
=======
		"traceroute-nanog":
		ensure => absent;
		"traceroute":
		ensure =>latest;
>>>>>>> production
	}

	file { "/etc/sudoers":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/sudo/sudoers.appserver";
	}
}
