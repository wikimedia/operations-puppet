# == Define: tcpircbot::instance
#
# Provisions a daemon that maintains a connection to IRC and listens on a
# server socket. Data read from the socket is forwarded to an IRC channel.
#
# === Parameters
#
# [*channel*]
#   Echo read messages to this IRC channel.
#
# [*nickname*]
#   Bot's preferred IRC nick. Should be registered with nickserv. Defaults to
#   the resource's title.
#
# [*password*]
#   Nickserv password for bot's nickname. The bot uses SASL to authenticate
#   itself with nickserv.
#
# [*server_host*]
#   Hostname of IRC server to which the bot should connect (default:
#   'chat.freenode.net').
#
# [*server_port*]
#   IRC server's port (default: 7000).
#
# [*cidr*]
#   IPv6 CIDR range. Optional. If defined, inbound connections from addresses
#   outside this range will be rejected. If not defined (the default), the
#   service will only accept connections from private and loopback IPs.
#   Example: "fc00::/7".
#
# [*ssl*]
#   Whether to use SSL to connect to IRC server (default: true).
#
# [*max_clients*]
#   Maximum number of simultaneous inbound connections (default: 5).
#
# [*listen_port*]
#   Port to listen on for messages (default: 9200).
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
define tcpircbot::instance(
	$channel,
	$password,
	$nickname    = $title,
	$server_host = 'chat.freenode.net',
	$server_port = 7000,
	$cidr        = undef,
	$ssl         = true,
	$max_clients = 5,
	$listen_port = 9200,
) {
	include tcpircbot

	file { "${tcpircbot::dir}/${title}.json":
		ensure  => present,
		content => template('tcpircbot/tcpircbot.json.erb'),
		require => User[$tcpircbot::user],
	}

	file { "/etc/init/tcpircbot-${title}.conf":
		ensure  => present,
		content => template('tcpircbot/tcpircbot.conf.erb'),
	}

	file { "/etc/init.d/tcpircbot-${title}":
		ensure => link,
		target => '/lib/init/upstart-job',
	}

	service { "tcpircbot-${title}":
		ensure   => running,
		provider => 'upstart',
		require  => [
			Package['python-irclib'],
			File["${tcpircbot::dir}/${title}.json"],
			File["/etc/init/tcpircbot-${title}.conf"]
		],
	}
}
