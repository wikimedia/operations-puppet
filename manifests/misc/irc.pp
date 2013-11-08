# IRC-related classes

class misc::ircecho {

	# To use this class, you must define some variables; here's an example
	# (leading hashes on channel names are added for you if missing):
	#  $ircecho_logs = {
	#    "/var/log/nagios/irc.log" => ["wikimedia-operations","#wikimedia-tech"],
	#    "/var/log/nagios/irc2.log" => "#irc2",
	#  }
	#  $ircecho_nick = "nagios-wm"
	#  $ircecho_server = "chat.freenode.net"

	package { "ircecho":
		ensure => latest;
	}

	service { "ircecho":
		require => Package[ircecho],
		ensure => running;
	}

	file {
		"/etc/default/ircecho":
			require => Package[ircecho],
			content => template('ircecho/default.erb'),
			owner => root,
			mode => 0755;
	}

	# bug 26784 - IRC bots process need nagios monitoring
    monitor_service { "ircecho": description => "ircecho_service_running", check_command => "nrpe_check_ircecho" }

}

