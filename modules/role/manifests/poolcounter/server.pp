class role::poolcounter::server {
    include ::poolcounter
    include base::firewall

    system::role { 'role::poolcounter':
        description => 'PoolCounter server',
    }

    # Process running
    nrpe::monitor_service { 'poolcounterd':
        description  => 'poolcounter',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:3 -C poolcounterd',
    }

    # TCP port 7531 reacheable
    monitoring::service { 'poolcounterd_port_7531':
        description   => 'Poolcounter connection',
        check_command => 'check_tcp!7531',
    }

    # firewalling
    ferm::service { 'poolcounterd':
        proto   => 'tcp',
        port    => '7531',
        srange  => '$DOMAIN_NETWORKS',
        notrack => true,
    }
}
