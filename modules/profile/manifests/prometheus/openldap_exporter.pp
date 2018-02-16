class profile::prometheus::openldap_exporter (
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    include passwords::openldap::labs

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    package { 'prometheus-openldap-exporter':
        ensure => present,
    }

    # Prometheus exporter needs Twisted 16.x
    if os_version('debian == jessie') {
        $twisted_packages = [
            'python-twisted-bin',
            'python-twisted-core',
            'python-twisted-mail',
            'python-twisted-names',
            'python-twisted-web'
        ]

        apt::pin { $twisted_packages:
            pin      => 'release a=jessie-backports',
            priority => '1001',
            before   => Package['prometheus-openldap-exporter'],
        }
    }

    $monitor_pass = $passwords::openldap::labs::monitor_pass
    file { '/etc/prometheus/openldap-exporter.yaml':
        ensure  => present,
        mode    => '0440',
        owner   => 'prometheus',
        group   => 'prometheus',
        content => template('profile/prometheus/prometheus.conf.erb'),
        notify  => Service['prometheus-openldap-exporter'],
    }

    service { 'prometheus-openldap-exporter':
        ensure  => running,
        require => File['/etc/prometheus/openldap-exporter.yaml'],
    }

    base::service_auto_restart { 'prometheus-openldap-exporter': }

    ferm::service { 'prometheus-openldap-exporter':
        proto  => 'tcp',
        port   => '9142',
        srange => $ferm_srange,
    }
}
