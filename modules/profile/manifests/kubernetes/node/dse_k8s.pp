# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::node::dse_k8s (
) {
    # See: https://docs.opensearch.org/2.19/install-and-configure/install-opensearch/index/#important-settings
    sysctl::parameters { 'opensearch':
        values   => {
            'vm.max_map_count'          => 262144,
        }
    }

    # Temporary firewall rule allowing stat hosts to egress to the postgresql-growthbook-rw.growthbook service VIP.
    # @mpopov will write a jupyter notebook to generate synthetic data in a schema Growthbook understands, and will
    # load it into the database, as part of T409591. Once the ticket is closed, we'll be able to remove that ferm rule.
    ferm::service { 'growthbook-pg-rw':
        proto  => 'tcp',
        port   => 5432,
        srange => '(@resolve((stat1008.eqiad.wmnet stat1009.eqiad.wmnet stat1010.eqiad.wmnet stat1011.eqiad.wmnet)))',
        drange => '10.67.44.231',
    }
}
