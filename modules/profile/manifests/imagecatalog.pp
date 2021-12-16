class profile::imagecatalog (
    Hash[String, Hash] $kubernetes_cluster_groups = lookup('kubernetes_cluster_groups'),
    Hash[String, Hash[String, Hash]] $tokens      = lookup('profile::kubernetes::infrastructure_users', {default_value => {}}),
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
    }.flatten().filter |$v| { $v =~ NotUndef }

    class {'imagecatalog':
        port                => 3691,
        data_dir            => '/srv/deployment/imagecatalog',
        kubernetes_clusters => $kubernetes_clusters,
    }
}
