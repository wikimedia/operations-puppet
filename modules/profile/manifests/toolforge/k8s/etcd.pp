class profile::toolforge::k8s::etcd (
    Array[Stdlib::Fqdn] $peer_hosts = lookup('profile::toolforge::k8s::etcd_nodes'),
) {
    class { 'profile::wmcs::etcd':
        peer_hosts   => $peer_hosts,
        backup_hosts => wmflib::role::hosts('wmcs::toolforge::k8s::etcd_backup'),
    }
    contain 'profile::wmcs::etcd'

    firewall::service { 'etcd-k8s-control':
        proto  => 'tcp',
        port   => 2379,
        srange => wmflib::role::hosts('wmcs::toolforge::k8s::control'),
    }
}
