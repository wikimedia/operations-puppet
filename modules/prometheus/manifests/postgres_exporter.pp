# == Class prometheus::postgres_exporter
# Install/configure postgresql prometheus exporter
#
class prometheus::postgres_exporter(
    $prometheus_user = 'prometheus',
    $prometheus_db = 'postgres',
    $ensure='present'
) {
    package { 'prometheus-postgres-exporter':
        ensure => $ensure,
    }

    if debian::codename::eq('stretch') {
        $postgres_exporter_extra_args = '-extend.query-path /etc/postgres-prometheus-exporter-queries.yaml'
    }

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

    service { 'prometheus-postgres-exporter':
        ensure => running,
        enable => true,
    }

    base::service_auto_restart { 'prometheus-postgres-exporter': }
}
