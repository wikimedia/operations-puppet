class etcd::v3::monitoring(Stdlib::HTTPSurl $endpoint) {
    # Check the daemon is running
    nrpe::monitor_systemd_unit_state { 'etcd':
        require => Service['etcd'],
    }

    # Just check the local health
    file { '/usr/local/bin/check_etcd_health':
        ensure  => present,
        source  => 'puppet:///modules/etcd/v3/check_etcd_health.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Service['etcd'],
    }

    nrpe::monitor_service{ 'etcd_cluster_health':
        description  => 'Etcd cluster health',
        nrpe_command => "/usr/local/bin/check_etcd_health ${endpoint}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Etcd',
    }
}
