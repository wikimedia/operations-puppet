# == Define: tcpircbot::instance
#
# Provisions a daemon that maintains a connection to IRC and listens on a
# server socket. Data read from the socket is forwarded to an IRC channel.
#
# === Parameters
#
# [*channels*]
#   Echo read messages to these IRC channels.
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
#   Allowed CIDR range. Optional. If defined, inbound connections from
#   addresses outside this range will be rejected. If not defined (the
#   default), the service will only accept connections from private and
#   loopback IPs.  Multiple ranges may be specified as an array of values.
#   Example: ['192.0.2.0/24', '2001:db8::/32']
#
# [*infiles*]
#   Read these files as extra inputs. Optional.
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
#     channels => '#wikimedia-operations',
#     password => $passwords::irc::announcebot,
#   }
#
define tcpircbot::instance(
    $channels,
    $password,
    $nickname    = $title,
    $server_host = 'chat.freenode.net',
    $server_port = 7000,
    $cidr        = undef,
    $infiles     = undef,
    $ssl         = true,
    $max_clients = 5,
    $listen_port = 9200,
) {
    include tcpircbot

    file { "${tcpircbot::dir}/${title}.json":
        ensure  => present,
        content => template('tcpircbot/tcpircbot.json.erb'),
        require => User['tcpircbot'],
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
        ensure    => running,
        provider  => 'upstart',
        subscribe => File["/etc/init/tcpircbot-${title}.conf", "${tcpircbot::dir}/${title}.json"],
        require   => [
            Class['tcpircbot'],
            File["${tcpircbot::dir}/${title}.json"],
        ],
    }
}
