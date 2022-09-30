# SPDX-License-Identifier: Apache-2.0
class profile::imagecatalog (
    Hash[String, Hash] $kubernetes_cluster_groups = lookup('kubernetes_cluster_groups'),
    Hash[String, Hash[String, Hash]] $tokens      = lookup('profile::kubernetes::infrastructure_users', {default_value => {}}),
    Stdlib::Fqdn $deployment_server               = lookup('deployment_server'),
) {
    $kubernetes_clusters = $kubernetes_cluster_groups.map |$cluster_group, $clusters| {
        $_tokens = $tokens[$cluster_group]
        $token = $_tokens['imagecatalog']
        if ($token) {
            $clusters.map |$cluster, $cluster_data| {
                $kubeconfig_path = "/etc/kubernetes/imagecatalog-${cluster}.config"
                if ($cluster_data['imagecatalog']) {
                    k8s::kubeconfig{ $kubeconfig_path:
                        master_host => $cluster_data['master'],
                        username    => 'imagecatalog',
                        token       => $token['token'],
                        owner       => 'imagecatalog',
                        group       => 'imagecatalog',
                    }
                    [$cluster, $kubeconfig_path]
                }
            }
        }
    }
    .reduce([]) |$acc, $v| { $acc + $v }  # Flatten one level to get an array of [cluster, path] tuples...
    .filter |$v| { $v =~ NotUndef }       # and remove the undef entries for clusters where imagecatalog isn't enabled.

    $ensure = $deployment_server ? {
        $::fqdn => 'present',
        default => 'absent'
    }

    class {'imagecatalog':
        port                => 3691,
        data_dir            => '/srv/deployment/imagecatalog',
        kubernetes_clusters => $kubernetes_clusters,
        ensure              => $ensure,
    }
}
