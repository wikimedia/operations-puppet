# IRC-related classes

class misc::irc-server {
	system_role { "misc::irc-server": description => "IRC server" }

$motd = "
*******************************************************
This is the Wikimedia RC->IRC gateway
*******************************************************
Sending messages to channels is not allowed.

A channel exists for all Wikimedia wikis which have been
changed since the last time the server was restarted. In
general, the name is just the domain name with the .org
left off. For example, the changes on the English Wikipedia
are available at #en.wikipedia

If you want to talk, please join one of the many
Wikimedia-related channels on irc.freenode.net.
"

	file {
		"/usr/local/ircd-ratbox/etc/ircd.conf":
			mode => 0444,
			owner => irc,
			group => irc,
			source => "puppet:///private/misc/ircd.conf";
		"/usr/local/ircd-ratbox/etc/ircd.motd":
			mode => 0444,
			owner => irc,
			group => irc,
			content => $motd;
		"/etc/apache2/sites-available/irc.wikimedia.org":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/irc.wikimedia.org";
	}

	# redirect http://irc.wikimedia.org to http://meta.wikimedia.org/wiki/IRC
	apache_site { irc: name => "irc.wikimedia.org" }

	# Doesn't work in Puppet 0.25 due to a bug
	service { ircd:
		provider => base,
		binary => "/usr/local/ircd-ratbox/bin/ircd",
		ensure => running;
	}

	# Monitoring
	monitor_service { ircd: description => "ircd", check_command => "check_ircd" }
}

class misc::mediawiki-irc-relay {
	include passwords::udpmxircecho

	$udpmxircecho_pass = $passwords::udpmxircecho::udpmxircecho_pass

	system_role { "misc::mediawiki-irc-relay": description => "MediaWiki RC to IRC relay" }

	package { "python-irclib": ensure => latest; }

	file { "/usr/local/bin/udpmxircecho.py":
		content => template("misc/udpmxircecho.py.erb"),
		mode => 0555,
		owner => irc,
		group => irc;
	}

	service { udpmxircecho:
		provider => base,
		binary => "/usr/local/bin/udpmxircecho.py",
		start => "/usr/local/bin/udpmxircecho.py rc-pmtpa ekrem.wikimedia.org",
		ensure => running;
	}
}

class misc::ircecho {

	# To use this class, you must define some variables; here's an example
	# (leading hashes on channel names are added for you if missing):
	#  $ircecho_logs = {
	#    "/var/log/nagios/irc.log" => ["wikimedia-operations","#wikimedia-tech"],
	#    "/var/log/nagios/irc2.log" => "#irc2",
	#  }
	#  $ircecho_nick = "nagios-wm"
	#  $ircecho_server = "irc.freenode.net"

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

