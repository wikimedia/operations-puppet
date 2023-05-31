# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::kubeconfig::admin () {
    k8s::fetch_clusters().map | String $name, K8s::ClusterConfig $config | {
        $default_admin = profile::pki::get_cert($config['pki_intermediate_base'], 'kubernetes-admin', {
            'renew_seconds'   => $config['pki_renew_seconds'],
            'names'           => [{ 'organisation' => 'system:masters' }],
            'owner'           => 'root',
            'outdir'          => '/etc/kubernetes/pki',
        })
        k8s::kubeconfig { "/etc/kubernetes/admin-${name}.config":
            master_host => $config['master'],
            username    => 'default-admin',
            auth_cert   => $default_admin,
            group       => 'root',
            owner       => 'root',
            mode        => '0400',
        }
    }
}
