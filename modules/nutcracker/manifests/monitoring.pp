# == Class: nutcracker::monitoring
#
# Provisions Icinga alerts for nutcracker.
#
class nutcracker::monitoring {
    nrpe::monitor_service { 'nutcracker':
        description  => 'nutcracker process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u nutcracker -C nutcracker',
    }

    nrpe::monitor_service { 'nutcracker_port':
        description  => 'nutcracker port',
        nrpe_command => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 11212 --timeout=2',
    }
}
