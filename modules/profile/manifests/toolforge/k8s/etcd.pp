class profile::toolforge::k8s::etcd (
    Array[Stdlib::Fqdn] $peer_hosts    = lookup('profile::toolforge::k8s::etcd_nodes',   {default_value => ['localhost']}),
    Array[Stdlib::Fqdn] $checker_hosts = lookup('profile::toolforge::checker_hosts',     {default_value => ['tools-checker-03.tools.eqiad.wmflabs']}),
    Array[Stdlib::Fqdn] $control_nodes = lookup('profile::toolforge::k8s::control_nodes',{default_value => ['localhost']}),
    Boolean             $bootstrap     = lookup('profile::etcd::cluster_bootstrap',      {default_value => false}),
) {
    class { '::profile::wmcs::kubeadm::etcd':
        peer_hosts    => $peer_hosts,
        checker_hosts => $checker_hosts,
        control_nodes => $control_nodes,
        bootstrap     => $bootstrap,
    }
    contain '::profile::wmcs::kubeadm::etcd'
}
