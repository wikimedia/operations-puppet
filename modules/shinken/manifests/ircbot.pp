# = Class: shinken::ircbot
#
# Sets up an ircecho instance that sends shinken alerts to IRC
class shinken::ircbot {
    include shinken::server

    file { '/var/log/ircecho':
        ensure  => directory,
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
        mode    => '0555',
    }

    $ircecho_logs   = {
        '/var/log/ircecho/irc.log'          => '#wikimedia-operations',
        '/var/log/ircecho/irc-qa.log'       => '#wikimedia-qa',
        '/var/log/ircecho/irc-labs.log'     => '#wikimedia-labs',
    }
    $ircecho_nick   = 'shinken-wm'
    $ircecho_server = 'chat.freenode.net'

    class { '::ircecho':
        ircecho_logs   => $ircecho_logs,
        ircecho_nick   => $ircecho_nick,
        ircecho_server => $ircecho_server,
        require        => File['/var/log/shinken/irc'],
    }
}
