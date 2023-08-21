# Prometheus Haproxy metrics exporter.

# === Parameters
#
# [*$endpoint*]
#  The stats_over_http Haproxy URL
#
# [*$listen_port*]
#  The TCP port to listen on
#
# [*$ensure*]
#  If it should be present or absent

class prometheus::haproxy_exporter (
    Stdlib::HTTPUrl $endpoint  = 'http://localhost:9100/?stats;csv',
    Stdlib::Port::User $listen_port = 9901,
    Wmflib::Ensure $ensure  = present,
) {
    ensure_packages('prometheus-haproxy-exporter', {
        ensure  => $ensure,
    })

    systemd::service { 'prometheus-haproxy-exporter':
        ensure  => $ensure,
        restart => true,
        content => systemd_template('prometheus-haproxy-exporter'),
    }

    profile::auto_restarts::service { 'prometheus-haproxy-exporter':
        ensure  => $ensure,
    }
}
