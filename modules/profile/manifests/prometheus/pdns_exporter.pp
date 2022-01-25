class profile::prometheus::pdns_exporter {
    ensure_packages('prometheus-pdns-exporter')

    service { 'prometheus-pdns-exporter':
        ensure  => running,
    }

    profile::auto_restarts::service { 'prometheus-pdns-exporter': }
}
