# Listens on a TCP port and forwards messages to an IRC channel.
# Connects to freenode via SSL and listens on TCP port 9200 by default.
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
# You can test it like this:
#
#   nc localhost 9200 <<<"Hello, IRC!"
#
# Logs to /var/log/upstart/tcpircbot-*.log
#
class tcpircbot (
	$user        = 'tcpircbot',
	$group       = 'tcpircbot',
	$dir         = '/srv/tcpircbot',
) {
	package { [ 'python-irclib', 'python-netaddr' ]:
		ensure => present,
	}

	if ! defined(Group[$group]) {
		group { $group:
			ensure => present,
		}
	}

	if ! defined(User[$user]) {
		user { $user:
			ensure     => present,
			gid        => $group,
			shell      => '/bin/false',
			home       => $dir,
			managehome => true,
			system     => true,
		}
	}

	file { "${dir}/tcpircbot.py":
		ensure => present,
		source => 'puppet:///modules/tcpircbot/tcpircbot.py',
		owner  => $user,
		group  => $group,
		mode   => '0555',
	}
}
