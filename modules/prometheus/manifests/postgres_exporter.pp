# == Class prometheus::postgres_exporter
# Install/configure postgresql prometheus exporter
#
class prometheus::postgres_exporter(
    $prometheus_user = 'prometheus',
    $prometheus_db = 'postgres',
    $ensure='present'
) {
    # Bookworm ships the exporter v1.11 which includes the pg_database exporter out of the box
    # and causes an error if re-defined here
    # In more recent releases, the exporter fully decommissioned queries.yaml
    if debian::codename::ge('bookworm') {
        $extended_query = false
    } else {
        $extended_query = true

        file { '/etc/postgres-prometheus-exporter-queries.yaml':
            ensure => $ensure,
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/prometheus/postgres/postgres-prometheus-exporter-queries.yaml',
            notify => Service['prometheus-postgres-exporter'],
        }
    }

    file { '/etc/default/prometheus-postgres-exporter':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('prometheus/prometheus-postgres-exporter.default.erb'),
    }

    package { 'prometheus-postgres-exporter':
        ensure  => $ensure,
        require => File['/etc/default/prometheus-postgres-exporter'],
    }

    service { 'prometheus-postgres-exporter':
        ensure    => running,
        enable    => true,
        require   => Package['prometheus-postgres-exporter'],
        subscribe => File['/etc/default/prometheus-postgres-exporter'],
    }

    profile::auto_restarts::service { 'prometheus-postgres-exporter': }
}
