# misc/bastion.pp

# bastion hosts

class misc::bastionhost {
	system_role { "misc::bastionhost": description => "Bastion" }

	require mysql_wmf::client

	include sudo::appserver

	package { "irssi":
		ensure => absent;
		"traceroute-nanog":
		ensure => absent;
		"traceroute":
		ensure =>latest;
	}

}
