# bots.pp

@monitor_group { "botserver": description => "wmf labs bot servers" }

class bots::packages {
	package { [ "mono-runtime", "php5", "php5-cli", "php5-common", "php5-curl", "mysql-client", "ksh", "csh", "lynx" ]:
		ensure => latest;
	}
}

class bots::monitoring {
	monitor_service { "ssh": description => "SSH", check_command => "check_ssh" }
}
