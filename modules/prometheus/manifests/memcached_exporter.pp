# == Define: prometheus::memcached_exporter
#
# Prometheus exporter for memcached server metrics.
#
# = Parameters
#
# [*arguments*]
#   Additional command line arguments for prometheus-memcached-exporter.

define prometheus::memcached_exporter (
    $arguments = '',
) {
    ensure_packages('prometheus-memcached-exporter')

    file { '/etc/default/prometheus-memcached-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${arguments}\"",
        notify  => Service['prometheus-memcached-exporter'],
    }

    service { 'prometheus-memcached-exporter':
        ensure  => running,
        require => Package['prometheus-memcached-exporter'],
    }

    profile::auto_restarts::service { 'prometheus-memcached-exporter': }
}
