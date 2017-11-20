# == Class postgresql::prometheus
# Install/configure postgresql prometheus exporter
#
class postgresql::prometheus(
    $prometheus_user = 'prometheus',
    $prometheus_db = 'postgres',
    $master = true,
    $ensure='present'
) {
    require ::postgresql::server

    package { 'prometheus-postgres-exporter':
        ensure => $ensure,
    }

    postgresql::user { 'prometheus@localhost':
        ensure   => $ensure,
        user     => $prometheus_user,
        database => $prometheus_db,
        type     => 'all',
        method   => 'peer',
        master   => $master,
    }

    file { '/etc/default/prometheus-postgres-exporter':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('postgresql/prometheus-postgres-exporter.default.erb'),
    }
    service { 'prometheus-postgres-exporter':
        ensure => running,
        enable => true,
    }
}
