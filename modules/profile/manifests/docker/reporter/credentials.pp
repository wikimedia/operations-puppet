# SPDX-License-Identifier: Apache-2.0
# @summary This profile deploys credentials needed by Docker Report.
# @param deploy_k8s_credentials true if the K8s TLS credentials need to be deployed.
class profile::docker::reporter::credentials(
    Boolean $deploy_k8s_credentials = lookup('profile::docker::reporter::credentials::deploy_k8s_credentials', {'default_value' => false}),
){
    # Ensure /etc/kubernetes/pki is created with proper permissions before the first pki::get_cert call
    # FIXME: https://phabricator.wikimedia.org/T337826
    $cert_dir = '/etc/kubernetes/pki'
    unless defined(File[$cert_dir]) {
        file { $cert_dir:
            ensure => bool2str($deploy_k8s_credentials, 'directory', 'absent'),
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    k8s::fetch_clusters(false).each | String $name, K8s::ClusterConfig $config | {
        $auth_cert = profile::pki::get_cert($config['pki_intermediate_base'], 'debmonitor', {
            'ensure'         => bool2str($deploy_k8s_credentials, 'present', 'absent'),
            'renew_seconds'  => $config['pki_renew_seconds'],
            'outdir'         => $cert_dir,
            'owner'          => 'root',
            # The debmonitor user does not have any organisation attributes (e.g. groups)
            # attached as it is being granted specific (limited) rights via RBAC.
        })

        $kubeconfig_path = "/etc/kubernetes/debmonitor-${name}.config"
        k8s::kubeconfig { $kubeconfig_path:
            ensure      => bool2str($deploy_k8s_credentials, 'present', 'absent'),
            master_host => $config['master'],
            username    => 'debmonitor',
            auth_cert   => $auth_cert,
        }
    }
}
