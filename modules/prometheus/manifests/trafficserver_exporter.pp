# Prometheus Traffic Server metrics exporter.

# === Parameters
#
# [*instance_name*]
#  Traffic server instance name (default: backend)
#
# [*$endpoint*]
#  The stats_over_http Traffic Server URL
#
# [*$listen_port*]
#  The TCP port to listen on

define prometheus::trafficserver_exporter (
    String $instance_name = 'backend',
    Stdlib::HTTPUrl $endpoint  = 'http://127.0.0.1/_stats',
    Wmflib::UserIpPort $listen_port = 9122,
) {
    require_package('prometheus-trafficserver-exporter')

    $service_name = "prometheus-trafficserver-${instance_name}-exporter"

    systemd::service { $service_name:
        ensure  => present,
        restart => true,
        content => systemd_template('prometheus-trafficserver-exporter@'),
    }

    monitoring::service { "trafficserver_${instance_name}_exporter_check_http":
        description   => "Ensure traffic_exporter binds on port ${listen_port} and responds to HTTP requests",
        check_command => "check_http_port_url!${listen_port}!/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server',
    }

    base::service_auto_restart { $service_name: }
}
