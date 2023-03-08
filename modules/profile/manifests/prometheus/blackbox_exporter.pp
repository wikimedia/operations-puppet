# SPDX-License-Identifier: Apache-2.0
# profile to provision prometheus blackbox / active checks exporter. See
# https://github.com/prometheus/blackbox_exporter and the module's documentation.

class profile::prometheus::blackbox_exporter {
    class { 'prometheus::blackbox_exporter': }

    # We need a deterministic location for client certificates to use for exported
    # blackbox checks e.g. prometheus::blackbox::check::{http,tcp} with use_client_auth
    puppet::expose_agent_certs { '/etc/prometheus':
        ensure          => 'present',
        user            => 'prometheus',
        provide_private => true,
    }

    ferm::service { 'prometheus-blackbox-exporter':
        proto  => 'tcp',
        port   => '9115',
        srange => '$DOMAIN_NETWORKS',
    }
}
