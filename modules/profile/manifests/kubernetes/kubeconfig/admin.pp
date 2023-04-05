# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::kubeconfig::admin (
    Hash[String, Hash[String, Hash]] $tokens = lookup('profile::kubernetes::infrastructure_users', { default_value => {} }),
) {
    k8s::fetch_clusters().map | String $name, K8s::ClusterConfig $config | {
        $_tokens = $tokens[$config['cluster_group']]
        k8s::kubeconfig { "/etc/kubernetes/admin-${name}.config":
            master_host => $config['master'],
            username    => 'client-infrastructure',
            token       => $_tokens['client-infrastructure']['token'],
            group       => 'root',
            owner       => 'root',
            mode        => '0400',
        }
    }
}
