class role::echoirc {
    include ircecho

    system::role { 'ircecho': description => 'ircecho server' }

    # bug 26784 - IRC bots process need nagios monitoring
    nrpe::monitor_service { 'ircecho':
        description  => 'ircecho_service_running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:4 -c 1:20 -a ircecho',
    }
}

