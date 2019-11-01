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
    package {'prometheus-hhvm-exporter':
        ensure => absent,
    }

    file { '/etc/default/prometheus-hhvm-exporter':
        ensure  => absent,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${arguments}\"",
    }
}
