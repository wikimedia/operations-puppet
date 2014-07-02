# == Class: twemproxy::monitoring
#
# Provisions Icinga alerts for twemproxy.
#
class twemproxy::monitoring {
    nrpe::monitor_service { 'twemproxy':
        description  => 'twemproxy process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:2 -u nobody -C nutcracker',
    }

    nrpe::monitor_service { 'twemproxy_port':
        description  => 'twemproxy port',
        nrpe_command => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 11211 --timeout=2',
    }
}
