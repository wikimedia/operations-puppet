# == Class: prometheus::memcached_exporter
#
# Prometheus exporter for memcached server metrics.
#
# = Parameters
#
# [*ensure*]
#   Ensure toggle.
#
# [*arguments*]
#   Additional command line arguments for prometheus-memcached-exporter.

class prometheus::memcached_exporter (
    Wmflib::Ensure $ensure    = 'present',
    String         $arguments = '',
) {
    package { 'prometheus-memcached-exporter':
        ensure => stdlib::ensure($ensure, 'package'),
    }

    file { '/etc/default/prometheus-memcached-exporter':
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${arguments}\"",
        notify  => Service['prometheus-memcached-exporter'],
    }

    service { 'prometheus-memcached-exporter':
        ensure  => stdlib::ensure($ensure, 'service'),
        require => Package['prometheus-memcached-exporter'],
    }

    profile::auto_restarts::service { 'prometheus-memcached-exporter':
        ensure => $ensure,
    }
}
