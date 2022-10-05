# SPDX-License-Identifier: Apache-2.0
class profile::prometheus::ircd_exporter {

    package { 'prometheus-ircd-exporter':
        ensure => absent,
    }

    service { 'prometheus-ircd-exporter':
        ensure => stopped,
    }

    profile::auto_restarts::service { 'prometheus-ircd-exporter':
        ensure => absent,
    }
}
