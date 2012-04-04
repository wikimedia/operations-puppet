# misc/bastion.pp

# bastion hosts

class misc::bastionhost {
	system_role { "misc::bastionhost": description => "Bastion" }

	require mysql::client

	package { "irssi":
		ensure => absent;
		"traceroute-nanog":
		ensure => absent;
		"traceroute":
		ensure =>latest;
	}

	file { "/etc/sudoers":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/sudo/sudoers.appserver";
	}

	file { "/h"       : ensure => link, target =>  "/home" }
	file { "/home/b"  : ensure => link, target =>  "bin" }
	file { "/home/c"  : ensure => link, target =>  "common" }
	file { "/home/d"  : ensure => link, target =>  "doc" }
	file { "/home/docs": ensure => link, target =>  "doc" }
	file { "/home/h"  : ensure => link, target =>  "htdocs" }
	file { "/home/l"  : ensure => link, target =>  "logs" }
	file { "/home/log": ensure => link, target =>  "logs" }
	file { "/home/s"  : ensure => link, target =>  "src" }
	file { "/home/w"  : ensure => link, target =>  "wikipedia" }

}

