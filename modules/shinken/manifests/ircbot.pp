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

    file { '/var/log/ircecho':
        ensure  => directory,
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
        mode    => '0775',
    }

    $ircecho_logs   = {
        '/var/log/ircecho/irc.log'          => '#wikimedia-operations',
        '/var/log/ircecho/irc-releng.log'       => '#wikimedia-releng',
        '/var/log/ircecho/irc-labs.log'     => '#wikimedia-labs',
        '/vat/log/ircecho/irc-wmt.log'      => '##wmt',
    }

    class { '::ircecho':
        ircecho_logs   => $ircecho_logs,
        ircecho_nick   => $nick,
        ircecho_server => $server,
        require        => File['/var/log/ircecho'],
    }
}
