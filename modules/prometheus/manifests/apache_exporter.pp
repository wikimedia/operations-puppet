# == Define: prometheus::apache_exporter
#
# Prometheus exporter for Apache httpd server metrics.
#
#
define prometheus::apache_exporter (){

    ensure_packages('prometheus-apache-exporter')

    file { '/etc/default/prometheus-apache-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => 'ARGS="--scrape_uri http://127.0.0.1/server-status/?auto"',
        notify  => Service['prometheus-apache-exporter'],
    }

    service { 'prometheus-apache-exporter':
        ensure  => running,
        require => Package['prometheus-apache-exporter'],
    }

    profile::auto_restarts::service { 'prometheus-apache-exporter': }
}
