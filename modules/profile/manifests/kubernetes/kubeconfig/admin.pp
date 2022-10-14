# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::kubeconfig::admin (
    Hash[String, Hash] $kubernetes_cluster_groups                      = lookup('kubernetes_cluster_groups'),
    Hash[String, Hash[String, Hash]] $tokens                           = lookup('profile::kubernetes::infrastructure_users', { default_value => {} }),
) {
    $kubernetes_cluster_groups.map |$cluster_group, $clusters| {
        $_tokens = $tokens[$cluster_group]
        $clusters.each |$cluster, $cluster_data| {
            k8s::kubeconfig { "/etc/kubernetes/admin-${cluster}.config":
                master_host => $cluster_data['master'],
                username    => 'client-infrastructure',
                token       => $_tokens['client-infrastructure']['token'],
                group       => 'root',
                owner       => 'root',
                mode        => '0400',
            }
        }
    }
}
