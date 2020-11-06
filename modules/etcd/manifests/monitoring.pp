# === Class etcd::monitoring
#
class etcd::monitoring {
    require etcd

    if debian::codename::ge('stretch') {
        $plugin_package = 'libmonitoring-plugin-perl'
        $plugin_file = 'etcd_cluster_health_stretch'
    } else {
        $plugin_package = 'libnagios-plugin-perl'
        $plugin_file = 'etcd_cluster_health'
    }

    ensure_packages($plugin_package)

    # For now, this is not critical, but should probably be in the future.
    nrpe::monitor_systemd_unit_state { 'etcd':
        require => Service['etcd'],
    }

    file { '/usr/local/bin/nrpe_etcd_cluster_health':
        ensure  => present,
        source  => "puppet:///modules/etcd/${plugin_file}",
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => [
            Package[$plugin_package],
            Service['etcd'],
        ]
    }

    sudo::user { 'nagios_check_etcd':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/local/bin/nrpe_etcd_cluster_health'],
    }

    nrpe::monitor_service{ 'etcd_cluster_health':
        description  => 'Etcd cluster health',
        nrpe_command => "/usr/local/bin/nrpe_etcd_cluster_health --url ${::etcd::adv_client_url}",
        require      => [
          File['/usr/local/bin/nrpe_etcd_cluster_health'],
          Sudo::User['nagios_check_etcd'],
        ],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Etcd',
    }

}
