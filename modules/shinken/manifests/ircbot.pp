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
    $nick,
    $server,
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
        '/var/log/ircecho/irc.log'                => '#wikimedia-operations',
        '/var/log/ircecho/irc-releng.log'         => '#wikimedia-releng',
        '/var/log/ircecho/irc-cloud.log'          => '#wikimedia-cloud',
        '/var/log/ircecho/irc-cloud-feed.log'     => '#wikimedia-cloud-feed',
        '/var/log/ircecho/irc-cvn.log'            => '#countervandalism',
        '/var/log/ircecho/irc-ores.log'           => '#wikimedia-ai',
    }

    class { '::ircecho':
        ircecho_logs   => $ircecho_logs,
        ircecho_nick   => $nick,
        ircecho_server => $server,
        require        => File['/var/log/ircecho'],
    }
}
