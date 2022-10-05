# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::pdns_rec_exporter {
    # Exporter written in Python 2, for Bullseye hosts use the built-in
    # metrics endpoint in newer PowerDNS versions (not available in Buster sadly)
    debian::codename::require::max('buster')

    ensure_packages('prometheus-pdns-rec-exporter')

    service { 'prometheus-pdns-rec-exporter':
        ensure  => running,
        require => Service['pdns-recursor'],
    }

    profile::auto_restarts::service { 'prometheus-pdns-rec-exporter': }
}
