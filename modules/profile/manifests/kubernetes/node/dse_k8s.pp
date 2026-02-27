# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::node::dse_k8s (
) {
    # See: https://docs.opensearch.org/2.19/install-and-configure/install-opensearch/index/#important-settings
    sysctl::parameters { 'opensearch':
        values   => {
            'vm.max_map_count'          => 262144,
        }
    }

    # This directory can be mounted by certain pods running in this cluster in order to support spark
    # local files. See https://spark.apache.org/docs/3.5.7/running-on-kubernetes.html#local-storage and #T412925
    file { '/srv/spark':
        ensure => directory,
    }
}
