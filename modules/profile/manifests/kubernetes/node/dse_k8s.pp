# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::node::dse_k8s (
) {
    # See: https://docs.opensearch.org/2.19/install-and-configure/install-opensearch/index/#important-settings
    sysctl::parameters { 'opensearch':
        values   => {
            'vm.max_map_count'          => 262144,
        }
    }
}
