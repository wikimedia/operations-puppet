# = Class: icinga::ircbot
#
# Sets up an ircecho instance that sends icinga alerts to IRC
class icinga::ircbot {

    $ircecho_logs   = {
        '/var/log/icinga/irc.log'          => '#wikimedia-operations',
        '/var/log/icinga/irc-wikidata.log' => '#wikidata',
        '/var/log/icinga/irc-releng.log'   => '#wikimedia-releng',
        '/var/log/icinga/irc-labs.log'     => '#wikimedia-labs',
    }
    $ircecho_nick   = 'icinga-wm'
    $ircecho_server = 'chat.freenode.net'

    class { '::ircecho':
        ircecho_logs    => $ircecho_logs,
        ircecho_nick    => $ircecho_nick,
        ircecho_server  => $ircecho_server,
    }

    # T28784 - IRC bots process need nagios monitoring
    nrpe::monitor_service { 'ircecho':
        description  => 'ircecho_service_running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:4 -c 1:20 -a ircecho',
    }

}
