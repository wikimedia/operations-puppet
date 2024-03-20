class profile::toolforge::k8s::etcd (
    Array[Stdlib::Fqdn] $peer_hosts = lookup('profile::toolforge::k8s::etcd_nodes', {default_value => ['localhost']}),
    Boolean             $bootstrap  = lookup('profile::etcd::cluster_bootstrap',    {default_value => false}),
) {
    class { '::profile::wmcs::kubeadm::etcd':
        peer_hosts    => $peer_hosts,
        control_nodes => wmflib::role::hosts('wmcs::toolforge::k8s::control'),
        bootstrap     => $bootstrap,
    }
    contain '::profile::wmcs::kubeadm::etcd'

    firewall::service {  'etcd_checker':
        proto  => 'tcp',
        port   => 2379,
        srange => wmflib::role::hosts('wmcs::toolforge::checker'),
    }
}
