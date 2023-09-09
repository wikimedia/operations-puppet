# @param status_port port that the internal nginx status page will listen on
class prometheus::nginx_exporter (
    Stdlib::Port $status_port = 19113,
) {
    ensure_packages('prometheus-nginx-exporter')

    nginx::status_site { 'prometheus-exporter':
        port => $status_port,
    }

    # in Debian Buster, the default is to produce metrics at :9113/metrics
    # extend the ARGS with more parameters if you need to change the defaults
    #
    # -web.listen-address string
    #   An address to listen on for web interface and telemetry. (default ":9113")
    # -web.telemetry-path string
    #   A path under which to expose metrics. (default "/metrics"
    file { '/etc/default/prometheus-nginx-exporter':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "ARGS='-nginx.scrape-uri=http://localhost:${status_port}/nginx_status'\n",
        require => Package['prometheus-nginx-exporter'],
    }

    service { 'prometheus-nginx-exporter':
        ensure    => running,
        subscribe => File['/etc/default/prometheus-nginx-exporter'],
        require   => Service['nginx'],
    }

    profile::auto_restarts::service { 'prometheus-nginx-exporter': }
}
