# SPDX-License-Identifier: Apache-2.0
class profile::imagecatalog (
    Stdlib::Fqdn $deployment_server = lookup('deployment_server'),
) {
    # Fetch clusters without aliases
    $kubernetes_clusters = k8s::fetch_clusters(false).map | String $name, K8s::ClusterConfig $config | {
        if ($config['imagecatalog']) {
            $username = 'imagecatalog'

            $auth_cert = profile::pki::get_cert($config['pki_intermediate_base'], $username, {
                'renew_seconds'  => $config['pki_renew_seconds'],
                'outdir'         => '/etc/kubernetes/pki',
                # imagecatalog user does not have any organisation attributes (e.g. groups)
                # attached as it is being granted specific (limited) rights via RBAC.
            })

            $kubeconfig_path = "/etc/kubernetes/imagecatalog-${name}.config"
            k8s::kubeconfig { $kubeconfig_path:
                master_host => $config['master'],
                username    => 'imagecatalog',
                auth_cert   => $auth_cert,
                owner       => 'imagecatalog',
                group       => 'imagecatalog',
            }
            [$name, $kubeconfig_path]
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
