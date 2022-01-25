class profile::prometheus::nutcracker_exporter {
    ensure_packages('prometheus-nutcracker-exporter')

    service { 'prometheus-nutcracker-exporter':
        ensure  => running,
    }
    profile::auto_restarts::service { 'prometheus-nutcracker-exporter': }
}
