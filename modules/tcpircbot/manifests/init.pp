# == Class: tcpircbot
#
# Base class for tcpircbot, a daemon that reads messages from a TCP socket and
# writes them to an IRC channel. You should not need to override the defaults
# for this class's parameters. You likely need to simply 'include tcpircbot'
# and then provision an instance by declaring a 'tcpircbot::instance' resource.
# See instance.pp for the configuration options you do need to specify.
#
# === Parameters
#
# [*user*]
#   Run tcpircbot instances as this system user (default: 'tcpircbot').
#
# [*group*]
#   Run tcpircbot under this gid (default: 'tcpircbot').
#
# [*dir*]
#   Directory for tcpircbot script and configuration files and home directory
#   for user.
#
# === Examples
#
# The following snippet will configure a bot nicknamed 'announcebot' that will
# sit on #wikimedia-operations on Freenode and forward messages that come in from
# private and loopback IPs on port 9200:
#
#   include tcpircbot
#
#   tcpircbot::instance { 'announcebot':
#     channel  => '#wikimedia-operations',
#     password => $passwords::irc::announcebot,
#   }
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
