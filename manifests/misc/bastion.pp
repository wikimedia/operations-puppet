# misc/bastion.pp

# bastion hosts

class misc::bastionhost {
	system_role { "misc::bastionhost": description => "Bastion" }

	require mysql::client
	
	package {
		"irssi":
			ensure => absent;
		"traceroute-nanog":
			ensure => absent;
		"traceroute":
			ensure =>latest;
	}

	if $::realm == 'labs' {
		include generic::packages::ack-grep
		include generic::packages::ack-grep::linked-to-ack
		include generic::packages::joe
		include generic::packages::tree
	}

	file { "/etc/sudoers":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/sudo/sudoers.appserver";
	}
}
