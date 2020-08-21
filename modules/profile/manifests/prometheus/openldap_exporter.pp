class profile::prometheus::openldap_exporter (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    String $monitor_pass = lookup('profile::prometheus::openldap_exporter::monitor_pass')
){

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    package { 'prometheus-openldap-exporter':
        ensure => present,
    }

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
