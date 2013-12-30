class role::echoirc {
    include ircecho

    system::role { 'ircecho': description => 'ircecho server' }

    # bug 26784 - IRC bots process need nagios monitoring
    monitor_service { "ircecho": description => "ircecho_service_running", check_command => "nrpe_check_ircecho" }
}

