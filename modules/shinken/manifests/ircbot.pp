# = Class: shinken::ircbot
#
# Sets up an ircecho instance that sends shinken alerts to IRC
#
# = Parameters
#
# [*nick*]
#   IRC Nick for the bot relaying notifications
#
# [*server*]
#   IRC server the bot should connect to
class shinken::ircbot(
    $nick = 'shinken-wm',
    $server = 'chat.freenode.net',
){
    include shinken

    file { '/var/log/ircbot':
        ensure  => directory,
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
        mode    => '0775',
    }

    tcpircbot::instance { $nick:
        channels => '#wikimedia-operations',
        server_host => $server,
        infiles => {
            '/var/log/ircbot/irc.log'        => '#wikimedia-operations',
            '/var/log/ircbot/irc-releng.log' => '#wikimedia-releng',
            '/var/log/ircbot/irc-labs.log'   => '#wikimedia-labs',
            '/var/log/ircbot/irc-cvn.log'    => '#countervandalism',
            '/var/log/ircbot/irc-wmt.log'    => '##wmt',
        }
    }
}
