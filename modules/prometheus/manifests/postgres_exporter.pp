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

    file { '/etc/default/prometheus-postgres-exporter':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/prometheus-postgres-exporter.default.erb'),
    }
    service { 'prometheus-postgres-exporter':
        ensure => running,
        enable => true,
    }
}
