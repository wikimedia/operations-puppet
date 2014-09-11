# role class for Icinga IRC bot
class role::echoirc {

    system::role { 'echoirc': description => 'server running icinga irc bot' }

    case $::realm {
        'production': {
            $ircecho_logs   = {
                '/var/log/icinga/irc.log'          => '#wikimedia-operations',
                '/var/log/icinga/irc-wikidata.log' => '#wikidata',
                '/var/log/icinga/irc-qa.log'       => '#wikimedia-qa',
                '/var/log/icinga/irc-labs.log'     => '#wikimedia-labs',
            }
            $ircecho_nick   = 'icinga-wm'
            $ircecho_server = 'chat.freenode.net'
        }
        'labs': {
            $ircecho_logs   = { '/var/log/icinga/irc.log' => '#wikimedia-labs' }
            $ircecho_nick   = 'icinga-wm-labs'
            $ircecho_server = 'chat.freenode.net'
        }
        default: {
            fail('unknown realm, please use labs or production')
        }
    }

    class { '::ircecho':
        ircecho_logs    => $ircecho_logs,
        ircecho_nick    => $ircecho_nick,
        ircecho_server  => $ircecho_server,
   }

    # bug 26784 - IRC bots process need nagios monitoring
    nrpe::monitor_service { 'ircecho':
        description  => 'ircecho_service_running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:4 -c 1:20 -a ircecho',
    }

}

