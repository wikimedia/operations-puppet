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

    base::service_auto_restart { 'prometheus-trafficserver-exporter': }
}
