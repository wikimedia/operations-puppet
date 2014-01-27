class gitblit::monitor {
    include nrpe

    nrpe::monitor_service { 'gitblit_process':
        description  => 'gitblit process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^/usr/bin/java .*-jar gitblit.jar'"
    }
}
