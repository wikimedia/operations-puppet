# SPDX-License-Identifier: Apache-2.0
# profile to provision prometheus blackbox / active checks exporter. See
# https://github.com/prometheus/blackbox_exporter and the module's documentation.

class profile::prometheus::blackbox_exporter {
    class { '::prometheus::blackbox_exporter': }

    ferm::service { 'prometheus-blackbox-exporter':
        proto  => 'tcp',
        port   => '9115',
        srange => '$DOMAIN_NETWORKS',
    }
}
