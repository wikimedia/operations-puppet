class profile::poolcounter {
    class {'::poolcounter' : }

    # Process running
    nrpe::monitor_service { 'poolcounterd':
        description  => 'poolcounter',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:3 -C poolcounterd',
        notes_url    => 'https://www.mediawiki.org/wiki/PoolCounter',
    }

    # TCP port 7531 reacheable
    monitoring::service { 'poolcounterd_port_7531':
        description   => 'Poolcounter connection',
        check_command => 'check_tcp!7531',
        notes_url     => 'https://www.mediawiki.org/wiki/PoolCounter',
    }

    # firewalling
    ferm::service { 'poolcounterd':
        proto   => 'tcp',
        port    => '7531',
        srange  => '$DOMAIN_NETWORKS',
        notrack => true,
    }
}
