# SPDX-License-Identifier: Apache-2.0
class profile::imagecatalog (
    Hash[String, Hash[String, Hash]] $tokens = lookup('profile::kubernetes::infrastructure_users', { default_value => {} }),
    Stdlib::Fqdn $deployment_server          = lookup('deployment_server'),
) {
    # Fetch clusters without aliases
    $kubernetes_clusters = k8s::fetch_clusters(false).map | String $name, K8s::ClusterConfig $config | {
        $_tokens = $tokens[$config['cluster_group']]
        $token = $_tokens['imagecatalog']
        if ($token) {
            if ($config['imagecatalog']) {
                $kubeconfig_path = "/etc/kubernetes/imagecatalog-${name}.config"
                k8s::kubeconfig { $kubeconfig_path:
                    master_host => $config['master'],
                    username    => 'imagecatalog',
                    token       => $token['token'],
                    owner       => 'imagecatalog',
                    group       => 'imagecatalog',
                }
                [$name, $kubeconfig_path]
            }
        }
    }
    .filter |$v| { $v =~ NotUndef }       # and remove the undef entries for clusters where imagecatalog isn't enabled.

    $ensure = $deployment_server ? {
        $::fqdn => 'present',
        default => 'absent'
    }

    class { 'imagecatalog':
        port                => 3691,
        data_dir            => '/srv/deployment/imagecatalog',
        kubernetes_clusters => $kubernetes_clusters,
        ensure              => $ensure,
    }
}
