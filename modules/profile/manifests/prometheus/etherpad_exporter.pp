# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::etherpad_exporter {

    ensure_packages('prometheus-etherpad-exporter')

    service { 'prometheus-etherpad-exporter':
        ensure  => running,
    }

    profile::auto_restarts::service { 'prometheus-etherpad-exporter': }
}
