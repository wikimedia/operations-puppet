class role::labs::openstack::nova::fullstack {
    system::role { $name: }

    $novaconfig = hiera_hash('novaconfig', {})
    $fullstack_pass = $novaconfig['osstackcanary_pass']

    class { '::openstack::nova::fullstack':
        password => $fullstack_pass,
    }

    nrpe::monitor_service { 'nova-fullstack':
        description  => 'nova instance creation test',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C python -a nova-fullstack',
    }
}
