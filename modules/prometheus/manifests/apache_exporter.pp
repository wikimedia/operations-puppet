# == Define: prometheus::apache_exporter
#
# Prometheus exporter for Apache httpd server metrics.
#
# = Parameters
#
# [*arguments*]
#   Additional command line arguments for prometheus-apache-exporter.

define prometheus::apache_exporter (
    $arguments = '-scrape_uri http://127.0.0.1/server-status/?auto',
) {
    require_package('prometheus-apache-exporter')

    file { '/etc/default/prometheus-apache-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${arguments}\"",
        notify  => Service['prometheus-apache-exporter'],
    }

    service { 'prometheus-apache-exporter':
        ensure  => running,
        require => Package['prometheus-apache-exporter'],
    }

    base::service_auto_restart { 'prometheus-apache-exporter': }
}
