# == Define: prometheus::druid_exporter
#
# Prometheus exporter for the Druid daemons.
#
# = Parameters
#
# [*arguments*]
#   Additional command line arguments for prometheus-druid-exporter.

define prometheus::druid_exporter (
    $arguments = '',
) {
    require_package('prometheus-druid-exporter')

    file { '/etc/default/prometheus-druid-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${arguments}\"",
        notify  => Service['prometheus-druid-exporter'],
    }

    service { 'prometheus-druid-exporter':
        ensure  => running,
        require => Package['prometheus-druid-exporter'],
    }

    base::service_auto_restart { 'prometheus-druid-exporter': }
}
