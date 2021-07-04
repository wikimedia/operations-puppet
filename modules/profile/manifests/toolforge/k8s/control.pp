# Note: To bootstrap a new cluster $kubernetes_version must match the version
# of packages in the $component repo
class profile::toolforge::k8s::control (
    Array[Stdlib::Fqdn] $etcd_hosts = lookup('profile::toolforge::k8s::etcd_nodes',     {default_value => ['localhost']}),
    Stdlib::Fqdn        $apiserver  = lookup('profile::toolforge::k8s::apiserver_fqdn', {default_value => 'k8s.example.com'}),
    String              $node_token = lookup('profile::toolforge::k8s::node_token',     {default_value => 'example.token'}),
    String              $calico_version = lookup('profile::toolforge::k8s::calico_version', {default_value => 'v3.18.4'}),
    Boolean             $typha_enabled = lookup('profile::toolforge::k8s::typha_enabled', {default_value => false}),
    Integer             $typha_replicas = lookup('profile::toolforge::k8s::typha_replicas', {default_value => 3}),
    Optional[String]    $encryption_key = lookup('profile::toolforge::k8s::encryption_key', {default_value => undef}),
    String              $kubernetes_version = lookup('profile::toolforge::k8s::kubernetes_version', {default_value => '1.15.5'}),
    Integer             $ingress_replicas   = lookup('profile::toolforge::k8s::ingress_replicas',   {default_value => 2}),
) {
    class { '::profile::wmcs::kubeadm::control':
        etcd_hosts         => $etcd_hosts,
        apiserver          => $apiserver,
        node_token         => $node_token,
        calico_version     => $calico_version,
        typha_enabled      => $typha_enabled,
        typha_replicas     => $typha_replicas,
        encryption_key     => $encryption_key,
        kubernetes_version => $kubernetes_version,
    }
    contain '::profile::wmcs::kubeadm::control'

    class { '::toolforge::k8s::config': }
    class { '::toolforge::k8s::nginx_ingress_yaml':
        ingress_replicas => $ingress_replicas,
    }
}
