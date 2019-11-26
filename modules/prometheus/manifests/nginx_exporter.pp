# === Parameters
#
# [*$nginx_scrape_uri*]
#  The URI where nginx is providing the raw stats page
#
class prometheus::nginx_exporter (
    Stdlib::HTTPUrl $nginx_scrape_uri = 'http://localhost:8080/nginx_status',
) {
    requires_os('debian >= buster')
    require_package('prometheus-nginx-exporter')

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
        content => "ARGS='-nginx.scrape-uri=${nginx_scrape_uri}'\n",
        require => Package['prometheus-nginx-exporter'],
    }

    service { 'prometheus-nginx-exporter':
        ensure    => running,
        subscribe => File['/etc/default/prometheus-nginx-exporter'],
    }

    base::service_auto_restart { 'prometheus-nginx-exporter': }
}
