# SPDX-License-Identifier: Apache-2.0
# Instantiate all prometheus instances for this host

class profile::prometheus::instances {
    $k8s_clusters = k8s::fetch_clusters()

    # XXX clean up moved instances
    prometheus::instances().each |$instance, $config| {
        if $facts['networking']['fqdn'] in $config['hosts'] {
            # k8s-related instances are handled separately
            if $config['k8s_cluster_name'] != undef {
                if $config['k8s_cluster_name'] in $k8s_clusters {
                    profile::prometheus::k8s { $instance: }
                }
            } else {
                include "profile::prometheus::${instance}"
            }
        }
    }
}
