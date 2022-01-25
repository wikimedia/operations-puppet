class profile::prometheus::pdns_rec_exporter {
    ensure_packages('prometheus-pdns-rec-exporter')

    service { 'prometheus-pdns-rec-exporter':
        ensure  => running,
        require => Service['pdns-recursor'],
    }

    profile::auto_restarts::service { 'prometheus-pdns-rec-exporter': }
}
