class profile::toolforge::k8s::kubeadm::master(
    Array[Stdlib::Fqdn] $etcd_hosts = lookup('profile::toolforge::k8s::etcd_hosts'),
    Stdlib::Fqdn        $apiserver  = lookup('profile::toolforge::k8s::apiserver'),
    String              $dns_domain = lookup('profile::toolforge::k8s::dns_domain'),
    String              $node_token = lookup('profile::toolforge::k8s::node_token'),
    Boolean             $swap       = lookup('swap_partition',                      {default_value => true}),
) {
    class { 'toolforge::k8s::kubeadm': }
    class { 'toolforge::k8s::kubeadm_init':
        etcd_hosts     => $etcd_hosts,
        apiserver      => $apiserver,
        pod_subnet     => '192.168.0.0/24', # TODO: review this
        service_subnet => '192.168.1.0/24', # TODO: review this
        dns_domain     => $dns_domain,
        node_token     => $node_token,
    }

    # kubeadm preflight checks:
    # Ncpu should be >= 2
    if $facts['processorcount'] < 2 {
        fail('Please apply this profile into a VM with nCPU >= 2')
    }
    # disable swap: kubelet doesn't want it
    if $swap {
        fail('Please set the swap_partition hiera key to false for this VM')
    }
    exec { 'toolforge_k8s_disable_swap_swapoff':
        command => '/sbin/swapoff -a',
        onlyif  => '/usr/bin/test $(swapon -s | wc -l) -gt 0',
    }
    exec { 'toolforge_k8s_disable_swap_fstab':
        command => '/bin/sed -i /none.*swap/d /etc/fstab',
        onlyif  => '/usr/bin/test $(grep swap /etc/fstab | wc -l) -gt 0',
    }
    exec { 'toolforge_k8s_disable_swap_partition':
        command => '/sbin/parted /dev/vda rm 2',
        onlyif  => '/usr/bin/test $(parted /dev/vda print | grep swap | grep ^[[:space:]]2 | wc -l) -gt 0',
    }
}
