class profile::poolcounter(
    $prometheus_nodes = lookup('prometheus_nodes'),
    $exporter_port = lookup('profile::poolcounter::exporter_port'),
) {
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

    require_package('poolcounter-prometheus-exporter')

    systemd::service { 'poolcounter-prometheus-exporter':
        ensure  => 'present',
        content => systemd_template('poolcounter-prometheus-exporter'),
        require => Package['poolcounter-prometheus-exporter'],
        restart => true,
    }

    $prometheus_nodes_str = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_nodes_str})) @resolve((${prometheus_nodes_str}), AAAA))"
    ferm::service { 'poolcounter-prometheus-exporter':
        proto  => 'tcp',
        port   => $exporter_port,
        srange => $ferm_srange,
    }
}
