class profile::prometheus::pdns_exporter {
    # Exporter written in Python 2, for Bullseye hosts use the built-in
    # metrics endpoint in newer PowerDNS versions (not available in Buster sadly)
    debian::codename::require::max('buster')

    ensure_packages('prometheus-pdns-exporter')

    service { 'prometheus-pdns-exporter':
        ensure  => running,
    }

    profile::auto_restarts::service { 'prometheus-pdns-exporter': }
}
