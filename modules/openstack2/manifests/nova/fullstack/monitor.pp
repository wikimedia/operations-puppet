class openstack2::nova::fullstack::monitor {
    nrpe::monitor_service { 'nova-fullstack':
        description  => 'nova instance creation test',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C python -a nova-fullstack',
    }
}
