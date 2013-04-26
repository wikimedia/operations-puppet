# Listens on a TCP port and forwards messages to an IRC channel.
# Connects to freenode via SSL by default.
#
# Example:
#
#  include tcpircbot
#
#  tcpircbot::instance { 'announcebot':
#    password => 'nickserv_secret123',
#    channel  => '#wikimedia-operations',
#  }
#
class tcpircbot (
	$user        = 'tcpircbot',
	$group       = 'tcpircbot',
	$dir         = '/srv/tcpircbot',
) {
	package { 'python-irclib':
		ensure => present,
	}

	group { $group:
		ensure => present,
	}

	user { $user:
		ensure     => present,
		gid        => $group,
		shell      => '/bin/false',
		home       => $dir,
		managehome => true,
		system     => true,
	}

	file { "${dir}/tcpircbot.py":
		ensure => present,
		source => 'puppet:///modules/tcpircbot/tcpircbot.py',
		owner  => $user,
		group  => $group,
		mode   => '0555',
	}
}
