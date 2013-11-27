class varnish::logging::monitor {
    nrpe::monitor_service { 'varnishncsa':
        description  => 'Varnish traffic logger',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 2:2 -c 2:4 -C varnishncsa',
    }
}
