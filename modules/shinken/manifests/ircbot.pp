# = Class: shinken::ircbot
#
# Sets up an ircecho instance that sends shinken alerts to IRC
class shinken::ircbot {
    include shinken::server

    file { '/var/log/shinken/irc':
        ensure  => directory,
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
    }

    $ircecho_logs   = {
        '/var/log/shinken/irc/irc.log'          => '#wikimedia-operations',
        '/var/log/shinken/irc/irc-qa.log'       => '#wikimedia-qa',
        '/var/log/shinken/irc/irc-labs.log'     => '#wikimedia-labs',
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
