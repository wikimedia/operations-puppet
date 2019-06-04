class profile::prometheus::rabbitmq_exporter (
    Array[Stdlib::Fqdn] $prometheus_nodes = lookup('prometheus_nodes'),
    $rabbit_monitor_username = hiera('profile::prometheus::rabbit_monitor_user'),
    $rabbit_monitor_password = hiera('profile::prometheus::rabbit_monitor_pass'),
) {
    $rabbit_host = 'localhost:15672'

    file { '/etc/prometheus/':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/prometheus/rabbitmq-exporter.yaml':
        ensure  => 'present',
        owner   => 'prometheus',
        group   => 'prometheus',
        mode    => '0440',
        content => template('profile/prometheus/rabbitmq-exporter.conf.erb'),
        require => File['/etc/prometheus/'],
    }

    require_package('prometheus-rabbitmq-exporter')

    service { 'prometheus-rabbitmq-exporter':
        ensure  => running,
        require => File['/etc/prometheus/rabbitmq-exporter.yaml'],
    }

    base::service_auto_restart { 'prometheus-rabbitmq-exporter': }

    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $prometheus_ferm_srange = "@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA)"
    ferm::service { 'prometheus-rabbitmq-exporter':
        proto  => 'tcp',
        port   => '9195',
        srange => $prometheus_ferm_srange,
    }
}
