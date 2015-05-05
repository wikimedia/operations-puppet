# === Class etcd::monitoring
#
class etcd::monitoring {
    require etcd

    # For now, this is not critical, but should probably be in the future.
    nrpe::monitor_systemd_unit{ 'etcd':
        require => Service['etcd'],
    }

    require_package 'libnagios-plugin-perl'

    file { '/usr/local/bin/nrpe_etcd_cluster_health':
        ensure  => present,
        source  => 'puppet:///modules/etcd/etcd_cluster_health',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Service['etcd'],
    }

    sudo::user { 'nagios_check_etcd':
        user       => 'nagios',
        privileges => ['ALL = NOPASSWD: /usr/local/bin/nrpe_etcd_cluster_health'],
    }

    nrpe::monitor_service{ 'etcd_cluster_health':
        description  => 'Etcd cluster health',
        nrpe_command => "/usr/local/bin/nrpe_etcd_cluster_health --url ${::etcd::client_url}",
        require      => [
          File['/usr/local/bin/etcd-cluster-health'],
          Sudo::User['nagios_check_etcd'],
        ],
    }

}
