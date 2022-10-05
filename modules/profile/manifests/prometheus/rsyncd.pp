# SPDX-License-Identifier: Apache-2.0
# Used for migrations / hardware refresh, but not continuously
class profile::prometheus::rsyncd (
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    Wmflib::Ensure $ensure = lookup('profile::prometheus::rsyncd::ensure'),
) {
    class {'rsync::server':
        ensure_service => stdlib::ensure($ensure, 'service'),
    }

    rsync::server::module { 'prometheus-data':
        ensure         => $ensure,
        path           => '/srv/prometheus',
        uid            => 'prometheus',
        gid            => 'prometheus',
        hosts_allow    => $prometheus_nodes,
        auto_ferm      => true,
        auto_ferm_ipv6 => true,
    }
}
