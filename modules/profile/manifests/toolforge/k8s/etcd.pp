class profile::toolforge::k8s::etcd (
    Array[Stdlib::Fqdn] $peer_hosts    = lookup('profile::toolforge::k8s::etcd_nodes',   {default_value => ['localhost']}),
    Array[Stdlib::Fqdn] $checker_hosts = lookup('profile::toolforge::checker_hosts',     {default_value => ['tools-checker-03.tools.eqiad.wmflabs']}),
    Boolean             $bootstrap     = lookup('profile::etcd::cluster_bootstrap',      {default_value => false}),
) {
    class { '::profile::wmcs::kubeadm::etcd':
        peer_hosts    => $peer_hosts,
        control_nodes => wmflib::role::hosts('wmcs::toolforge::k8s::control'),
        bootstrap     => $bootstrap,
    }
    contain '::profile::wmcs::kubeadm::etcd'

    ferm::service {  'etcd_checker':
        proto  => 'tcp',
        port   => 2379,
        srange => "@resolve((${checker_hosts.join(' ')}))",
    }
}
