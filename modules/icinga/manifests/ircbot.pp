# = Class: icinga::ircbot
#
# Sets up an ircecho instance that sends icinga alerts to IRC
class icinga::ircbot(
    $ensure='present'
) {
    $ircecho_logs   = {
        '/var/log/icinga/irc.log'             => '#wikimedia-operations',
        '/var/log/icinga/irc-wikidata.log'    => '#wikidata',
        '/var/log/icinga/irc-releng.log'      => '#wikimedia-releng',
        '/var/log/icinga/irc-labs.log'        => '#wikimedia-cloud',
        '/var/log/icinga/irc-analytics.log'   => '#wikimedia-analytics',
        '/var/log/icinga/irc-ores.log'        => '#wikimedia-ai',
        '/var/log/icinga/irc-interactive.log' => '#wikimedia-interactive',
        '/var/log/icinga/irc-performance.log' => '#wikimedia-perf-bots',
        '/var/log/icinga/irc-fundraising.log' => '#wikimedia-fundraising',
        '/var/log/icinga/irc-reading-web.log' => '#wikimedia-reading-web-bots',
    }
    $ircecho_nick   = 'icinga-wm'
    $ircecho_server = 'chat.freenode.net +6697'

    class { '::ircecho':
        ensure         => $ensure,
        ircecho_logs   => $ircecho_logs,
        ircecho_nick   => $ircecho_nick,
        ircecho_server => $ircecho_server,
    }

    # T28784 - IRC bots process need nagios monitoring
    nrpe::monitor_service { 'ircecho':
        ensure       => $ensure,
        description  => 'ircecho_service_running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:4 -c 1:20 -a ircecho',
    }
}
