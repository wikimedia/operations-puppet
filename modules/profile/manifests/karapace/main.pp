# SPDX-License-Identifier: Apache-2.0
class profile::karapace::main (
    String $bootstrap_uri = lookup('karapace::bootstrap_uri'),
) {
    class { 'karapace':
        bootstrap_uri => $bootstrap_uri,
    }

    firewall::service { 'karapace':
        proto    => 'tcp',
        port     => 8081,
        src_sets => ['DOMAIN_NETWORKS'],
    }
}
