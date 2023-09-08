# == Class prometheus::postgres_exporter
# Install/configure postgresql prometheus exporter
#
class prometheus::postgres_exporter(
    $prometheus_user = 'prometheus',
    $prometheus_db = 'postgres',
    $ensure='present'
) {
    file { '/etc/default/prometheus-postgres-exporter':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/prometheus-postgres-exporter.default.erb'),
    }

    file { '/etc/postgres-prometheus-exporter-queries.yaml':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/prometheus/postgres/postgres-prometheus-exporter-queries.yaml',
    }

    package { 'prometheus-postgres-exporter':
        ensure  => $ensure,
        require => [
            File['/etc/default/prometheus-postgres-exporter'],
            File['/etc/postgres-prometheus-exporter-queries.yaml'],
        ],
    }

    service { 'prometheus-postgres-exporter':
        ensure    => running,
        enable    => true,
        require   => Package['prometheus-postgres-exporter'],
        subscribe => [
            File['/etc/default/prometheus-postgres-exporter'],
            File['/etc/postgres-prometheus-exporter-queries.yaml'],
        ],
    }

    profile::auto_restarts::service { 'prometheus-postgres-exporter': }
}
