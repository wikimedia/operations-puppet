class varnish::logging::monitor($num_instances) {
    $r = "${num_instances}:${num_instances}"
    nrpe::monitor_service { 'varnishncsa':
        description  => 'Varnish traffic logger',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w $r -c $r -C varnishncsa",
    }
}
