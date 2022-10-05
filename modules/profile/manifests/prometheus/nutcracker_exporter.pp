# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::nutcracker_exporter {
    ensure_packages('prometheus-nutcracker-exporter')

    service { 'prometheus-nutcracker-exporter':
        ensure  => running,
        require => Package['prometheus-nutcracker-exporter'],
    }
    profile::auto_restarts::service { 'prometheus-nutcracker-exporter': }
}
