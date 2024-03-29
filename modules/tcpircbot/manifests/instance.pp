# SPDX-License-Identifier: Apache-2.0
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
#   'irc.libera.chat').
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
# sit on #wikimedia-operations on Libera.chat and forward messages that come in from
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
    $server_host = 'irc.libera.chat',
    $server_port = 7000,
    $cidr        = undef,
    $infiles     = undef,
    $ssl         = true,
    $max_clients = 5,
    $listen_port = 9200,
    $ensure      = 'present',
) {
    require tcpircbot

    file { "${tcpircbot::dir}/tcpircbot-${title}.json":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('tcpircbot/tcpircbot.json.erb'),
        require => User['tcpircbot'],
    }

    $service_name = "tcpircbot-${title}"

    systemd::service { $service_name:
        ensure    => $ensure,
        restart   => true,
        content   => systemd_template('tcpircbot'),
        subscribe => File["${tcpircbot::dir}/tcpircbot-${title}.json"],
    }
}
