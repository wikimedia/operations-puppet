# == Define: prometheus::mcrouter_exporter
#
# Prometheus exporter for mcrouter server metrics.
#
# = Parameters
#
# [*arguments*]
#   Additional command line arguments for prometheus-mcrouter-exporter.

define prometheus::mcrouter_exporter (
    $arguments = '',
) {
    ensure_packages('prometheus-mcrouter-exporter')

    file { '/etc/default/prometheus-mcrouter-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${arguments}\"",
        notify  => Service['prometheus-mcrouter-exporter'],
    }

    service { 'prometheus-mcrouter-exporter':
        ensure  => running,
        require => Package['prometheus-mcrouter-exporter'],
    }
}
