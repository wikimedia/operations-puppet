# Note: To bootstrap a new cluster $kubernetes_version must match the version
# of packages in the $component repo
class profile::toolforge::k8s::control (
    Array[Stdlib::Fqdn]        $etcd_hosts = lookup('profile::toolforge::k8s::etcd_nodes',     {default_value => ['localhost']}),
    Stdlib::Fqdn               $apiserver  = lookup('profile::toolforge::k8s::apiserver_fqdn', {default_value => 'k8s.example.com'}),
    String                     $node_token = lookup('profile::toolforge::k8s::node_token',     {default_value => 'example.token'}),
    Optional[String]           $encryption_key = lookup('profile::toolforge::k8s::encryption_key', {default_value => undef}),
    String                     $kubernetes_version = lookup('profile::toolforge::k8s::kubernetes_version', {default_value => '1.15.5'}),
    # Set these in the puppet secret repo for each deployment
    Hash[String[1], String[1]] $toolforge_secrets = lookup('profile::toolforge::k8s::secrets', {default_value => {}}),
) {
    class { '::profile::wmcs::kubeadm::control':
        etcd_hosts         => $etcd_hosts,
        apiserver          => $apiserver,
        node_token         => $node_token,
        encryption_key     => $encryption_key,
        kubernetes_version => $kubernetes_version,
    }
    contain '::profile::wmcs::kubeadm::control'

    class { '::toolforge::k8s::config': }
    class { '::toolforge::k8s::nginx_ingress_yaml': }
    class { '::toolforge::k8s::deployer':
        toolforge_secrets => $toolforge_secrets,
    }

    apt::package_from_component { 'thirdparty-k9s':
        component => 'thirdparty/k9s',
        packages  => ['k9s']
    }
}
