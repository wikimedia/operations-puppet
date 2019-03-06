# Prometheus Traffic Server metrics exporter.

# === Parameters
#
# [*$endpoint*]
#  The stats_over_http Traffic Server URL
#
# [*$listen_port*]
#  The TCP port to listen on

define prometheus::trafficserver_exporter (
    Stdlib::HTTPUrl $endpoint  = 'http://127.0.0.1/_stats',
    Wmflib::UserIpPort $listen_port = 9122,
) {
    require_package('prometheus-trafficserver-exporter')

    systemd::service { 'prometheus-trafficserver-exporter':
        ensure  => present,
        restart => true,
        content => systemd_template('prometheus-trafficserver-exporter@'),
    }

    monitoring::service { 'trafficserver_exporter_check_http':
        description   => "Ensure traffic_exporter binds on port ${listen_port} and responds to HTTP requests",
        check_command => "check_http_port_url!${listen_port}!/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    base::service_auto_restart { 'prometheus-trafficserver-exporter': }
}
