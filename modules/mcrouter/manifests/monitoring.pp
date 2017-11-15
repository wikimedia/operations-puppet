# == Class: mcrouter::monitoring
#
# Provisions Icinga alerts for mcrouter.
#
class mcrouter::monitoring($port = 11213) {
    nrpe::monitor_service { 'mcrouter':
        description  => 'mcrouter process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u mcrouter -C mcrouter',
    }

    if ($port != 0) {
        nrpe::monitor_service { 'mcrouter_port':
            description  => 'mcrouter port',
            nrpe_command => "/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p ${port} --timeout=2",
        }
    }
}
