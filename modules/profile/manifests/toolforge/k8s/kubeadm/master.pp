class profile::toolforge::k8s::kubeadm::master(
    Array[Stdlib::Fqdn] $etcd_hosts = lookup('profile::toolforge::k8s::etcd_hosts'),
    Stdlib::Fqdn        $apiserver  = lookup('profile::toolforge::k8s::apiserver'),
    String              $node_token = lookup('profile::toolforge::k8s::node_token'),
) {
    require profile::toolforge::k8s::kubeadm::preflight_checks

    class { 'toolforge::k8s::kubeadm': }

    $pod_subnet = '192.168.0.0/16'
    class { 'toolforge::k8s::kubeadm_init':
        etcd_hosts => $etcd_hosts,
        apiserver  => $apiserver,
        pod_subnet => $pod_subnet,
        node_token => $node_token,
    }

    class { 'toolforge::k8s::kubeadm_join':
        apiserver  => $apiserver,
        node_token => $node_token,
    }

    class { 'toolforge::k8s::kubeadm_calico':
        pod_subnet     => $pod_subnet,
    }
}
