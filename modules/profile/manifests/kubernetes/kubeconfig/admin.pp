# SPDX-License-Identifier: Apache-2.0
class profile::kubernetes::kubeconfig::admin () {
    # Ensure /etc/kubernetes/pki is created with proper permissions before the first pki::get_cert call
    # FIXME: https://phabricator.wikimedia.org/T337826
    $cert_dir = '/etc/kubernetes/pki'
    unless defined(File[$cert_dir]) {
        file { $cert_dir:
            ensure => 'directory',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    k8s::fetch_clusters().map | String $name, K8s::ClusterConfig $config | {
        $default_admin = profile::pki::get_cert($config['pki_intermediate_base'], 'kubernetes-admin', {
            'renew_seconds'   => $config['pki_renew_seconds'],
            'names'           => [{ 'organisation' => 'system:masters' }],
            'owner'           => 'root',
            'outdir'          => $cert_dir,
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
