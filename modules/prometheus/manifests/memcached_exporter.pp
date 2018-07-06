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
    require_package('prometheus-memcached-exporter')

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

    base::service_auto_restart { 'prometheus-memcached-exporter': }
}
