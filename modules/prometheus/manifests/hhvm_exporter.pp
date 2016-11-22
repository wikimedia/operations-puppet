# == Define: prometheus::hhvm_exporter
#
# Prometheus exporter for hhvm server metrics.
#
# = Parameters
#
# [*arguments*]
#   Additional command line arguments for prometheus-hhvm-exporter.

define prometheus::hhvm_exporter (
    $arguments = '',
) {
    require_package('prometheus-hhvm-exporter')

    file { '/etc/default/prometheus-hhvm-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${arguments}\"",
        notify  => Service['prometheus-hhvm-exporter'],
    }

    service { 'prometheus-hhvm-exporter':
        ensure  => running,
        require => Package['prometheus-hhvm-exporter'],
    }
}
