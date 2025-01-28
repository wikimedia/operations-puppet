class profile::poolcounter(
    $exporter_port = lookup('profile::poolcounter::exporter_port'),
) {
    class {'::poolcounter' : }

    # firewalling
    ferm::service { 'poolcounterd':
        proto   => 'tcp',
        port    => '7531',
        srange  => '$DOMAIN_NETWORKS',
        notrack => true,
    }

    ensure_packages('poolcounter-prometheus-exporter')

    systemd::service { 'poolcounter-prometheus-exporter':
        ensure  => 'present',
        content => systemd_template('poolcounter-prometheus-exporter'),
        require => Package['poolcounter-prometheus-exporter'],
        restart => true,
    }
}
