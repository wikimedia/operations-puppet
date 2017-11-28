class profile::openstack::base::nodepool::monitor {

    nrpe::monitor_service { 'nodepoold':
        description   => 'nodepoold running',
        contact_group => 'contint',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u nodepool --ereg-argument-array="^/usr/bin/python /usr/bin/nodepoold -d"',
    }

    nrpe::monitor_service { 'nodepoold_instance_state':
        description   => 'Check for valid instance states',
        contact_group => 'contint',
        nrpe_command  => '/usr/local/bin/check_nodepool_states',
    }
}
