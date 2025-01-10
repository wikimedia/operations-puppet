# SPDX-License-Identifier: Apache-2.0
# Instantiate all prometheus instances for this host

class profile::prometheus::instances {
    # On LVM systems, ensure that this host's instances filesystems are provisioned
    # Said provisioning is done by prometheus-provision-fs and the user is prompted to run it.
    # We could let Puppet do the provisioning, but we generally refrain from
    # automated LVM/FS operations in production.
    if ! $facts['lvm_support'] {
        $lvs_to_create = []
    } else {
        $lvs_to_create = prometheus::instances().map |$instance, $config| {
            $lv_name = "prometheus-${instance}"
            $lv_size = $config['provision_lv_size']
            if $facts['networking']['fqdn'] in $config['hosts']
                and ! $facts['logical_volumes'][$lv_name] {
                "prometheus-provision-fs ${instance} ${lv_size}"
            } else {
              []
            }
        }.flatten
    }

    if ! empty($lvs_to_create) {
        $lvs_msg = $lvs_to_create.join("\n")
        fail("Prometheus filesystems are missing, provision with:\n\n${lvs_msg}\n\n")
    }

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
