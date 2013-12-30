class role::ircecho {
    include ircecho

	# bug 26784 - IRC bots process need nagios monitoring
    monitor_service { "ircecho": description => "ircecho_service_running", check_command => "nrpe_check_ircecho" }
}

